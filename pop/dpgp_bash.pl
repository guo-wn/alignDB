#!/usr/bin/perl
use strict;
use warnings;

use Template;
use File::Basename;
use File::Find::Rule;
use File::Remove qw(remove);
use File::Spec;
use String::Compare;
use YAML qw(Dump Load DumpFile LoadFile);

my $store_dir = shift
    || File::Spec->catdir( $ENV{HOME}, "data/alignment/dpgp" );

{    # on linux
    my $data_dir    = File::Spec->catdir( $ENV{HOME}, "data/alignment/dpgp" );
    my $pl_dir      = File::Spec->catdir( $ENV{HOME}, "Scripts" );
    my $kentbin_dir = File::Spec->catdir( $ENV{HOME}, "bin/x86_64" );

    # dpgp2 africa
    my $seq_dir = File::Spec->catdir( $ENV{HOME}, "data/DPGP/process/" );

    my @data = (
        { taxon => 900701, name => "CK1",   coverage => 37.80, },
        { taxon => 900702, name => "CO15N", coverage => 41.30, },
        { taxon => 900703, name => "ED10N", coverage => 36.23, },
        { taxon => 900704, name => "EZ5N",  coverage => 33.81, },    #
        { taxon => 900705, name => "FR217", coverage => 38.44, },
        { taxon => 900706, name => "GA185", coverage => 47.37, },
        { taxon => 900707, name => "GU10",  coverage => 37.08, },
        { taxon => 900708, name => "KN6",   coverage => 37.05, },
        { taxon => 900709, name => "KR39",  coverage => 33.0, },     #
        { taxon => 900710, name => "KT1",   coverage => 35.21, },
        { taxon => 900711, name => "NG3N",  coverage => 36.97, },
        { taxon => 900712, name => "RC1",   coverage => 28.41, },    #
        { taxon => 900713, name => "RG15",  coverage => 41.30, },
        { taxon => 900714, name => "SP254", coverage => 40.78, },
        { taxon => 900715, name => "TZ8",   coverage => 33.76, },    #
        { taxon => 900716, name => "UG7",   coverage => 36.39, },
        { taxon => 900717, name => "UM526", coverage => 42.83, },
        { taxon => 900718, name => "ZI268", coverage => 39.92, },
        { taxon => 900719, name => "ZL130", coverage => 42.65, },
        { taxon => 900720, name => "ZO12",  coverage => 38.76, },
        { taxon => 900721, name => "ZS37",  coverage => 39.11, },
    );

    my @files = File::Find::Rule->file->name('*.vcf.fasta')->in($seq_dir);

    for my $item ( sort @data ) {
        my $name = $item->{name};

        # match the most similar name
        my ($file) = map { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map { [ $_, compare( lc basename($_), lc $item->{name} ) ] } @files;
        $item->{seq} = $file;

        # prepare working dir
        my $dir = File::Spec->catdir( $data_dir, $name );
        mkdir $dir if !-e $dir;
        $item->{dir} = $dir;
    }

    print Dump \@data;

    my $tt = Template->new;

    # taxon.csv
    my $text = <<'EOF';
[% FOREACH item IN data -%]
[% item.taxon %],Drosophila,melanogaster,[% item.name %],,
[% END -%]
EOF
    $tt->process(
        \$text,
        { data => \@data, },
        File::Spec->catfile( $store_dir, "taxon.csv" )
    ) or die Template->error;

    # chr_length.csv
    $text = <<'EOF';
[% FOREACH item IN data -%]
[% item.taxon %],chrUn,999999999,[% item.name %]/DPGP
[% END -%]
EOF
    $tt->process(
        \$text,
        { data => \@data, },
        File::Spec->catfile( $store_dir, "chr_length.csv" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# unzip, filter and split
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
echo [% item.name %]

cd [% item.dir %]
find [% item.dir %] -name "*.fa" -o -name "*.fasta" | xargs rm
[% kentbin_dir %]/faSplit byname [% item.seq %] .
~/perl5/bin/rename 's/fa$/fasta/' *.fa

[% END -%]

EOF

    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_file.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# repeatmasker on all fasta
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
bsub -q mpi_2 -n 8 -J [% item.name %]-rm RepeatMasker [% item.dir %]/*.fasta -species Flies -xsmall --parallel 8

[% END -%]

#----------------------------#
# find failed rm jobs
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
find [% item.dir %] -name "*fasta" \
    | perl -e \
    'while(<>) {chomp; s/\.fasta$//; next if -e qq{$_.fasta.masked}; next if -e qq{$_.fa}; print qq{ bsub -n 8 -J [% item.name %]_ RepeatMasker $_.fasta -species Flies -xsmall --parallel 8 \n};}' >> catchup.txt

[% END -%]

# find [% data_dir %] -name "*.fasta.masked" | sed "s/\.fasta\.masked$//" | xargs -i echo mv {}.fasta.masked {}.fa | sh

EOF

    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_rm.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# blastz
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
bsub -q mpi_2 -n 8 -J [% item.name %]-bz perl [% pl_dir %]/blastz/bz.pl -dt [% data_dir %]/Dmel_65 -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/Dmelvs[% item.name %] -s set01 -p 8 --noaxt -pb lastz --lastz

[% END -%]

#----------------------------#
# lpcna
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/lpcna.pl -dt [% data_dir %]/Dmel_65 -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/Dmelvs[% item.name %] -p 8

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_bz.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
    
#----------------------------#
# amp
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/amp.pl -syn -dt [% data_dir %]/Dmel_65 -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/Dmelvs[% item.name %] -p 8

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data        => [ { name => "Dsim_65" }, @data ],
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_amp.sh" )
    ) or die Template->error;

    $text = <<'EOF';
cd [% data_dir %]

#----------------------------#
# stat
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
find [% data_dir %]/Dmelvs[% item.name %]/axtNet -name "*.axt.gz" | xargs gzip -d
perl [% pl_dir %]/alignDB/extra/two_way_batch.pl -d Dmelvs[% item.name %] -t="7227,Dmel" -q "[% item.taxon %],[% item.name %]" -a [% data_dir %]/Dmelvs[% item.name %] -at 10000 -st 10000000 --parallel 6 --run 1-3,21,40
gzip [% data_dir %]/Dmelvs[% item.name %]/axtNet/*.axt

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => [ { name => "Dsim_65", taxon => 7240 }, @data ],
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_stat.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
    
#----------------------------#
# tar-gzip
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
cd [% data_dir %]/Dmelvs[% item.name %]/

tar -czvf lav.tar.gz   [*.lav   --remove-files
tar -czvf psl.tar.gz   [*.psl   --remove-files
tar -czvf chain.tar.gz [*.chain --remove-files
gzip *.chain
gzip net/*
gzip axtNet/*.axt

[% END -%]

#----------------------------#
# clean RepeatMasker outputs
#----------------------------#
# find [% data_dir %] -name "*.fasta*" | xargs rm

#----------------------------#
# only keeps chr.2bit files
#----------------------------#
# find [% data_dir %] -name "*.fa" | xargs rm

#----------------------------#
# clean pairwise maf
#----------------------------#
find [% data_dir %] -name "mafSynNet" | xargs rm -fr
find [% data_dir %] -name "mafNet" | xargs rm -fr

#----------------------------#
# gzip maf, fas
#----------------------------#
find [% data_dir %] -name "*.maf" | parallel gzip
find [% data_dir %] -name "*.maf.fas" | parallel gzip

#----------------------------#
# clean maf-fasta
#----------------------------#
# rm -fr [% data_dir %]/*_fasta


EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_clean.sh" )
    ) or die Template->error;
}

{    # on linux
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/dpgp" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );

    my $tt = Template->new;

    my $strains_of = {
        Dmelvs14 => [
            qw{ CK1 CO15N CO2 CO4N ED10N FR207 FR217 FR229 FR361 GA125 GA129
                GA130 GA132 }
        ],
    };

    my @group;
    for my $dbname ( sort keys %{$strains_of} ) {
        my @strains = @{ $strains_of->{$dbname} };
        my $dbs     = join ',', map { "Dmelvs" . $_ } @strains;
        my $queries = join ',',
            map { $_ . "query" } ( 1 .. scalar @strains - 1 );
        push @group,
            {
            goal_db  => $dbname,
            outgroup => '0query',
            target   => '0target',
            dbs      => $dbs,
            queries  => $queries,
            };
    }

    my $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

[% FOREACH item IN data -%]
# [% item.goal_db %]
perl [% pl_dir %]/alignDB/extra/join_dbs.pl --crude_only \
    --dbs [% item.dbs %] \
    --goal_db [% item.goal_db %] --outgroup [% item.outgroup %] \
    --target [% item.target %] \
    --queries [% item.queries %] \
    --no_insert=1 --trimmed_fasta=1 --length 10000

perl [% pl_dir %]/alignDB/util/refine_fasta.pl \
    --msa mafft -p 4 \
    -i [% data_dir %]/[% item.goal_db %].crude \
    -o [% data_dir %]/[% item.goal_db %]_mft

perl [% pl_dir %]/tool/catfasta2phyml.pl -f [% data_dir %]/[% item.goal_db %]_mft/*.fas > [% data_dir %]/all.fasta

perl [% pl_dir %]/alignDB/extra/multi_way_batch.pl -d [% item.goal_db %] -e fly_65 -f [% data_dir %]/[% item.goal_db %]_mft  -lt 1000 -st 10000000 --parallel 8 --run all

[% END -%]
EOF

    $tt->process(
        \$text,
        { data => \@group, data_dir => $data_dir, pl_dir => $pl_dir, },
        File::Spec->catfile( $store_dir, "auto_dpgp_joins.sh" )
    ) or die Template->error;
}

{    # multiz
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/dpgp" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );

    my $tt         = Template->new;
    my $strains_of = {
        DmelvsXIV   => [qw{ Dsim_65 CO15N GA185 RG15 SP254 UM526 ZL130 }],
        DmelvsXVIII => [
            qw{ Dsim_65 CK1 CO15N ED10N FR217 GA185 GU10 KN6 KT1 NG3N
                RG15 SP254 UG7 UM526 ZI268 ZL130 ZO12 ZS37 }
        ],
        DmelvsXXII => [
            qw{ Dsim_65 CK1 CO15N ED10N EZ5N FR217 GA185 GU10 KN6 KR39 KT1 NG3N
                RC1 RG15 SP254 TZ8 UG7 UM526 ZI268 ZL130 ZO12 ZS37 }
        ],
    };

    my @data;
    for my $key ( sort keys %{$strains_of} ) {
        my @strains = @{ $strains_of->{$key} };
        push @data,
            {
            out_dir => $key,
            strains => \@strains,
            };
    }

    my $text = <<'EOF';
#!/bin/bash
    
#----------------------------#
# mz
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
bsub -q mpi_2 -n 8 -J [% item.out_dir %]-mz perl [% pl_dir %]/blastz/mz.pl \
    [% FOREACH st IN item.strains -%]
    -d [% data_dir %]/Dmelvs[% st FILTER ucfirst %] \
    [% END -%]
    --tree [% data_dir %]/22way.nwk \
    --out [% data_dir %]/[% item.out_dir %] \
    -syn -p 8

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => \@data,
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_mz.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#----------------------------#
# maf2fasta
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
perl [% pl_dir %]/alignDB/util/maf2fasta.pl \
    --has_outgroup --id 7227 -p 8 --block \
    -i [% data_dir %]/[% item.out_dir %] \
    -o [% data_dir %]/[% item.out_dir %]_fasta

[% END -%]

#----------------------------#
# mafft
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
bsub -q mpi_2 -n 8 -J [% item.out_dir %]-mft perl [% pl_dir %]/alignDB/util/refine_fasta.pl \
    --msa mafft --block -p 8 \
    -i [% data_dir %]/[% item.out_dir %]_fasta \
    -o [% data_dir %]/[% item.out_dir %]_mft

[% END -%]

#----------------------------#
# muscle
#----------------------------#
#[% FOREACH item IN data -%]
## [% item.out_dir %]
#bsub -q mpi_2 -n 8 -J [% item.out_dir %]-msl perl [% pl_dir %]/alignDB/util/refine_fasta.pl \
#    --msa muscle --block -p 8 \
#    -i [% data_dir %]/[% item.out_dir %]_fasta \
#    -o [% data_dir %]/[% item.out_dir %]_msl
#
#[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => \@data,
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_maf_fasta.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
    
#----------------------------#
# multi_way_batch
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
# mafft
perl [% pl_dir %]/alignDB/extra/multi_way_batch.pl \
    -d [% item.out_dir %] -e fly_65 \
    --block --id 7227 \
    -f [% data_dir %]/[% item.out_dir %]_mft  \
    -lt 5000 -st 1000000 --parallel 8 --run 1-3,21,40

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => \@data,
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_dpgp_multi.sh" )
    ) or die Template->error;
}