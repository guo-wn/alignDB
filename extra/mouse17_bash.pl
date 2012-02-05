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
    || File::Spec->catdir( $ENV{HOME}, "data/alignment/mouse17" );

{    # on linux
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/mouse17" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );
    my $kentbin_dir = File::Spec->catdir( $ENV{HOME}, "bin/x86_64" );

    # nature 2011
    my $seq_dir = File::Spec->catdir( $ENV{HOME}, "data/sanger/mouse_reseq" );

    my $tt = Template->new;

    my @data = (
        { taxon => 900302, name => "129P2",       coverage => 43.78, },
        { taxon => 900303, name => "129S1_SvImJ", coverage => 27.25, },
        { taxon => 900304, name => "129S5",       coverage => 19.05, },
        { taxon => 900305, name => "A_J",         coverage => 26.68, },
        { taxon => 900306, name => "AKR_J",       coverage => 40.61, },
        { taxon => 900307, name => "BALBc_J",     coverage => 24.9, },
        { taxon => 900308, name => "C3H_HeJ",     coverage => 35.17, },
        { taxon => 900301, name => "C57BL_6N",    coverage => 29.29, },
        { taxon => 900309, name => "CAST_Ei",     coverage => 24.57, },
        { taxon => 900310, name => "CBA_J",       coverage => 29.34, },
        { taxon => 900311, name => "DBA_2J",      coverage => 24.67, },
        { taxon => 900312, name => "LP_J",        coverage => 27.67, },
        { taxon => 900313, name => "NOD",         coverage => 28.75, },
        { taxon => 900314, name => "NZO",         coverage => 17.31, },
        { taxon => 900315, name => "PWK_Ph",      coverage => 25.38, },
        { taxon => 900316, name => "Spretus_Ei",  coverage => 26.68, },
        { taxon => 900317, name => "WSB_Ei",      coverage => 18.26, },
    );

    my @files = File::Find::Rule->file->name('*.gz')->in($seq_dir);

    for my $item ( sort @data ) {

        # match the most similar name
        my ($file) = map { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map { [ $_, compare( lc basename($_), lc $item->{name} ) ] } @files;
        $item->{file} = $file;

        # prepare working dir
        my $dir = File::Spec->catdir( $data_dir, $item->{name} );
        mkdir $dir if !-e $dir;
        $item->{dir} = $dir;
    }

    my $basecount = File::Spec->catfile( $data_dir, "basecount.txt" );
    remove( \1, $basecount ) if -e $basecount;

    # taxon.csv
    my $text = <<'EOF';
[% FOREACH item IN data -%]
[% item.taxon %],Mus,musculus,[% item.name %],,
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
[% item.taxon %],chrUn,999999999,[% item.name %]/mouse17/sanger
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
gzip -d -c [% item.file %] > [% data_dir %]/[% item.name %].fasta
[% kentbin_dir %]/faFilter -minSize=10000 [% data_dir %]/[% item.name %].fasta [% data_dir %]/[% item.name %].10k.fasta
rm [% data_dir %]/[% item.name %].fasta

[% kentbin_dir %]/faSplit about [% item.file %] 100000000 [% item.dir %]/
rm [% data_dir %]/[% item.name %].10k.fasta

find [% item.dir %] -name "*.fa" | sed "s/\.fa$//" | xargs -i echo mv {}.fa {}.fasta | sh

[% END -%]

EOF

    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_file.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# repeatmasker
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
RepeatMasker [% item.dir %]/*.fasta -species mouse -xsmall -s --parallel 4

[% END -%]

[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
find [% item.dir %] -name "*.fasta.masked" | sed "s/\.fasta\.masked$//" | xargs -i echo mv {}.fasta.masked {}.fa | sh
# find [% item.dir %] | grep -v fa$ | xargs rm -fr

[% END -%]

EOF

    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_rm.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# repeatmasker on all fasta
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
# for i in [% item.dir %]/*.fasta; do bsub -n 8 -J [% item.name %]_`basename $i .fasta` RepeatMasker $i -species mouse -xsmall -s --parallel 8; done;
bsub -n 8 -J [% item.name %] RepeatMasker [% item.dir %]/*.fasta -species mouse -xsmall -s --parallel 8

[% END -%]

#----------------------------#
# find failed rm jobs
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl -e 'for $i (0..30) { $i = sprintf qq{%02d}, $i; $str = qq{[% item.dir %]/$i}; next if ! -e qq{$str.fasta}; next if -e qq{$str.fasta.masked}; next if -e qq{$str.fa}; print qq{ bsub -n 8 -J [% item.name %]_$i RepeatMasker $str.fasta -species mouse -xsmall -s --parallel 8 \n};}' >> catchup.txt

[% END -%]

# find [% data_dir %] -name "*.fasta.masked" | sed "s/\.fasta\.masked$//" | xargs -i echo mv {}.fasta.masked {}.fa | sh
# find [% item.dir %] | grep -v fa$ | xargs rm -fr

EOF

    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_rm_bsub.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# blastz
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/bz.pl -dt [% data_dir %]/Mouse9 -dq [% data_dir %]/[% item.name %] \
    -dl [% data_dir %]/Mousevs[% item.name %] -s set01 -p 4 --noaxt -pb lastz --lastz

[% END -%]

#----------------------------#
# lpcna
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/lpcna.pl -dt [% data_dir %]/Mouse9 -dq [% data_dir %]/[% item.name %] \
    -dl [% data_dir %]/Mousevs[% item.name %]

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_bz.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# blastz
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
# for i in [% data_dir %]/Mouse9/*.fa; do echo 'for j in [% data_dir %]/[% item.name %]/*.fa; do bsub lastz '$i' $j  E=30 O=400 Y=3400 L=2200 K=3000 Q=[% pl_dir %]/blastz/matrix/similar --ambiguous=iupac --output=[% data_dir %]/Mousevs[% item.name %]/`basename '$i' .fa`-`basename $j .fa`.lav; done'; done
bsub -n 8 -J [% item.name %] perl [% pl_dir %]/blastz/bz.pl -dt [% data_dir %]/Mouse9 -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/Mousevs[% item.name %] -s set01 -p 8 --noaxt -pb lastz --lastz

[% END -%]

#----------------------------#
# lpcna
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
bsub -n 8 -J [% item.name %] perl [% pl_dir %]/blastz/lpcna.pl -dt [% data_dir %]/Mouse9 -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/Mousevs[% item.name %] -p 8

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_bz_bsub.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash

#----------------------------#
# tar-gzip
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
cd [% data_dir %]/Mousevs[% item.name %]/

tar -czvf lav.tar.gz   [*.lav   --remove-files
tar -czvf psl.tar.gz   [*.psl   --remove-files
tar -czvf chain.tar.gz [*.chain --remove-files
gzip *.chain
gzip net/*
gzip axtNet/*.axt

[% END -%]

#----------------------------#
# only keeps chr.2bit files
#----------------------------#
# find [% data_dir %] -name "*.fa" | xargs rm
# find [% data_dir %] -name "*.fasta" | xargs rm
# find [% data_dir %] -name "*.fasta.cat" | xargs rm
# find [% data_dir %] -name "*.fasta.out" | xargs rm
# find [% data_dir %] -name "*.fasta.ref" | xargs rm
# find [% data_dir %] -name "*.fasta.tbl" | xargs rm

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_clean.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
    
#----------------------------#
# amp
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/amp.pl -dt [% data_dir %]/Mouse9 -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/Mousevs[% item.name FILTER ucfirst %] -p 8

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_amp.sh" )
    ) or die Template->error;
}

{    # on linux
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/mouse17" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );

    my $tt = Template->new;

    my @data = (
        { taxon => 900302, name => "129P2",       coverage => 43.78, },
        { taxon => 900303, name => "129S1_SvImJ", coverage => 27.25, },
        { taxon => 900304, name => "129S5",       coverage => 19.05, },
        { taxon => 900305, name => "A_J",         coverage => 26.68, },
        { taxon => 900306, name => "AKR_J",       coverage => 40.61, },
        { taxon => 900307, name => "BALBc_J",     coverage => 24.9, },
        { taxon => 900308, name => "C3H_HeJ",     coverage => 35.17, },
        { taxon => 900301, name => "C57BL_6N",    coverage => 29.29, },
        { taxon => 900309, name => "CAST_Ei",     coverage => 24.57, },
        { taxon => 900310, name => "CBA_J",       coverage => 29.34, },
        { taxon => 900311, name => "DBA_2J",      coverage => 24.67, },
        { taxon => 900312, name => "LP_J",        coverage => 27.67, },
        { taxon => 900313, name => "NOD",         coverage => 28.75, },
        { taxon => 900314, name => "NZO",         coverage => 17.31, },
        { taxon => 900315, name => "PWK_Ph",      coverage => 25.38, },
        { taxon => 900316, name => "Spretus_Ei",  coverage => 26.68, },
        { taxon => 900317, name => "WSB_Ei",      coverage => 18.26, },
    );

    my $text = <<'EOF';
cd /d [% data_dir %]

REM #----------------------------#
REM # stat
REM #----------------------------#
[% FOREACH item IN data -%]
REM # [% item.name %] [% item.coverage %]
perl [% pl_dir %]\alignDB\extra\two_way_batch.pl -d Mousevs[% item.name %] -t="10090,Mouse" -q "[% item.taxon %],[% item.name %]" -a [% data_dir %]\Mousevs[% item.name %] -at 10000 -st 10000000 --parallel 4 --run 1-3,21,40

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => \@data,
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_stat.sh" )
    ) or die Template->error;

    my $strains_of = {
        MousevsNine => [
            qw{ Spretus_Ei_1k 129P2 129S1_SvImJ A_J AKR_J C3H_HeJ CBA_J LP_J NOD }
        ],
        MousevsEleven => [
            qw{ Spretus_Ei_1k 129P2 129S1_SvImJ A_J AKR_J C3H_HeJ CBA_J LP_J NOD
                CAST_Ei PWK_Ph }
        ],
        MousevsThirteen => [
            qw{ Spretus_Ei_1k 129P2 129S1_SvImJ 129S5 A_J AKR_J BALBc_J C3H_HeJ
                CBA_J DBA_2J LP_J NOD NZO }
        ],
        MousevsSixteen => [
            qw{ Spretus_Ei_1k 129P2 129S1_SvImJ 129S5 A_J AKR_J BALBc_J C3H_HeJ
                CBA_J DBA_2J LP_J NOD NZO CAST_Ei PWK_Ph WSB_Ei }
        ],
    };

    my @group;
    for my $dbname ( sort keys %{$strains_of} ) {
        my @strains = @{ $strains_of->{$dbname} };
        my $dbs     = join ',', map { "Mousevs" . $_ } @strains;
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

    $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

[% FOREACH item IN data -%]
# [% item.goal_db %]
perl [% pl_dir %]/alignDB/extra/join_dbs.pl --dbs [% item.dbs %] --goal_db [% item.goal_db %] --outgroup [% item.outgroup %] --target [% item.target %] --queries [% item.queries %] --no_insert=1 --trimmed_fasta=1 --length 1000

perl [% pl_dir %]/alignDB/extra/multi_way_batch.pl -d [% item.goal_db %] -e mouse_65 -f [% data_dir %]/[% item.goal_db %]  -lt 1000 -st 10000000 --parallel 8 --run all

[% END -%]
EOF

    $tt->process(
        \$text,
        { data => \@group, data_dir => $data_dir, pl_dir => $pl_dir, },
        File::Spec->catfile( $store_dir, "auto_mouse17_multi.sh" )
    ) or die Template->error;
}

{    # multiz
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/mouse17" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );

    my $tt         = Template->new;
    my $strains_of = {

        # small sample
        MousevsV => [qw{ 129P2 A_J AKR_J C3H_HeJ NOD }],

        # coverage > 25x
        MousevsVIIIGE25xS =>
            [qw{ 129P2 A_J AKR_J C3H_HeJ CBA_J LP_J NOD Spretus_Ei }],
        MousevsVIIIGE25xP =>
            [qw{ 129P2 A_J AKR_J C3H_HeJ CBA_J LP_J NOD PWK_Ph }],
        MousevsVIIIGE25xC =>
            [qw{ 129P2 A_J AKR_J C3H_HeJ CBA_J LP_J NOD CAST_Ei }],
        MousevsVIIIGE25xW =>
            [qw{ 129P2 A_J AKR_J C3H_HeJ CBA_J LP_J NOD WSB_Ei }],

        # add all sub-species strains
        MousevsXIGE25xWCPS => [
            qw{ 129P2 A_J AKR_J C3H_HeJ CBA_J LP_J NOD WSB_Ei PWK_Ph CAST_Ei
                Spretus_Ei }
        ],

        # use this
        MousevsXII => [
            qw{ 129P2 A_J AKR_J BALBc_J C3H_HeJ CBA_J DBA_2J LP_J NOD NZO WSB_Ei
                CAST_Ei }
        ],

        # all
        MousevsXVI => [
            qw{ 129P2 129S1_SvImJ 129S5 A_J AKR_J BALBc_J C3H_HeJ CBA_J DBA_2J
                LP_J NOD NZO WSB_Ei PWK_Ph CAST_Ei Spretus_Ei }
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
    -d [% data_dir %]/Mousevs[% st FILTER ucfirst %] \
    [% END -%]
    --tree [% data_dir %]/17way.nwk \
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
        File::Spec->catfile( $store_dir, "auto_mouse17_mz.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#----------------------------#
# maf2fasta
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
perl [% pl_dir %]/alignDB/util/maf2fasta.pl \
    --has_outgroup --id 9606 -p 8 --block \
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
    -o [% data_dir %]/[% item.out_dir %]_mafft

[% END -%]

#----------------------------#
# muscle-quick
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
bsub -q mpi_2 -n 8 -J [% item.out_dir %]-msl perl [% pl_dir %]/alignDB/util/refine_fasta.pl \
    --msa muscle --quick --block -p 8 \
    -i [% data_dir %]/[% item.out_dir %]_fasta \
    -o [% data_dir %]/[% item.out_dir %]_muscle

[% END -%]

#----------------------------#
# clean
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
cd [% data_dir %]
rm -fr [% item.out_dir %]_fasta

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => \@data,
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_mouse17_maf_fasta.sh" )
    ) or die Template->error;
}
