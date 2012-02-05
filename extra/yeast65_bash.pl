#!/usr/bin/perl
use strict;
use warnings;

use Template;

#----------------------------------------------------------#
# RepeatMasker has been done
#----------------------------------------------------------#
my $store_dir = shift
    || File::Spec->catdir( $ENV{HOME}, "data/alignment/yeast65" );

{    # on linux
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/yeast65" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );
    my $kentbin_dir = File::Spec->catdir( $ENV{HOME}, "bin/x86_64" );

    my $tt   = Template->new;
    my @data = (
        { taxon => 226125, name => 'Spar',   coverage => '7x', },
        { taxon => 285006, name => 'RM11',   coverage => '10x', },
        { taxon => 307796, name => 'YJM789', coverage => '10x', },

        {   taxon    => 574961,
            name     => 'JAY291',
            coverage => '12x 454; 58x solexa s; 95x solexa p',
        },
        {   taxon    => 538975,
            name     => 'Sigma1278b',
            coverage => '45x sanger/solexa',
        },
        { taxon => 643680, name => 'EC1118', coverage => '24x unknown', },

        # wustl 11 yeast strains
        {   taxon    => 929587,
            name     => 'CBS_7960',
            coverage => '7.3x 454; 9.69x sanger',
        },
        {   taxon    => 464025,
            name     => 'CLIB215',
            coverage => '6.8x 454; 10.09 sanger',
        },
        {   taxon    => 929629,
            name     => 'CLIB324',
            coverage => '3.2x 454; 3.94x sanger',
        },
        { taxon => 947035, name => 'CLIB382', coverage => '5.96x 454', },
        {   taxon    => 947036,
            name     => 'FL100',
            coverage => '3.2x 454; 3.2x sanger',
        },
        { taxon => 947039, name => 'PW5', coverage => '16.10x 454', },
        { taxon => 929585, name => 'T7',  coverage => '25.4x 454/sanger', },
        { taxon => 471859, name => 'T73', coverage => '13.9x 454', },
        { taxon => 947040, name => 'UC5', coverage => '15.7x 454', },
        {   taxon    => 462210,
            name     => 'Y10',
            coverage => '2.8x 454; 3.81x sanger',
        },
        {   taxon    => 929586,
            name     => 'YJM269',
            coverage => '7.1x 454; 9.59x sanger',
        },

        # wine
        { taxon => 764097, name => 'AWRI796',     coverage => '20x 454', },
        { taxon => 764101, name => 'FostersO',    coverage => '20x 454', },
        { taxon => 764102, name => 'FostersB',    coverage => '20x 454', },
        { taxon => 764098, name => 'Lalvin_QA23', coverage => '20x 454', },
        { taxon => 764099, name => 'Vin13',       coverage => '20x 454', },
        { taxon => 764100, name => 'VL3',         coverage => '20x 454', },

        { taxon => 1095001, name => 'EC9_8', coverage => '30x 454', },
        {   taxon    => 721032,
            name     => 'Kyokai_no__7',
            coverage => '9.1x sanger',
        },

        { taxon => 545124, name => 'AWRI1631', coverage => '7x 454', },
        { taxon => 538975, name => 'M22',      coverage => '2.6x sanger', },
        { taxon => 538976, name => 'YPS163',   coverage => '2.8x sanger', },

        # sgrp data
        { taxon => 900003, name => 'DBVPG6765', coverage => '3x sanger', },
        {   taxon    => 580239,
            name     => 'SK1',
            coverage => '3.27x sanger; 15.61x solexa',
        },
        {   taxon    => 580240,
            name     => 'W303',
            coverage => '2.33x sanger; 3.01x solexa',
        },
        {   taxon    => 900001,
            name     => 'Y55',
            coverage => '3.42x sanger; 8.94x solexa',
        },
    );

    my $text = <<'EOF';
#!/bin/bash
cd [% data_dir %]

#----------------------------#
# blastz
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/bz.pl -dt [% data_dir %]/S288C -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/S288Cvs[% item.name %] -s set01 -p 4 --noaxt -pb lastz --lastz

[% END -%]

#----------------------------#
# lpcna
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/lpcna.pl -dt [% data_dir %]/S288C -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/S288Cvs[% item.name %] -p 4

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_yeast65_bz.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
    
#----------------------------#
# tar-gzip
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
cd [% data_dir %]/S288Cvs[% item.name %]/

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

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_yeast65_clean.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#!/bin/bash
    
#----------------------------#
# amp
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %] [% item.coverage %]
perl [% pl_dir %]/blastz/amp.pl -dt [% data_dir %]/S288C -dq [% data_dir %]/[% item.name %] -dl [% data_dir %]/S288Cvs[% item.name %] -p 4

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data        => \@data,
            data_dir    => $data_dir,
            pl_dir      => $pl_dir,
            kentbin_dir => $kentbin_dir
        },
        File::Spec->catfile( $store_dir, "auto_yeast65_amp.sh" )
    ) or die Template->error;
    
    $text = <<'EOF';
cd [% data_dir %]

#----------------------------#
# stat
#----------------------------#
[% FOREACH item IN data -%]
# [% item.name %]
perl [% pl_dir %]/alignDB/extra/two_way_batch.pl -d S288Cvs[% item.name %] -t="4932,S288C" -q "[% item.taxon %],[% item.name %]" -a [% data_dir %]/S288Cvs[% item.name %] -at 1000 -st 1000000 --parallel 4 --run 1-3,21,40

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => \@data,
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_primates_stat.sh" )
    ) or die Template->error;
}

{    # multi
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/yeast65" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );
    
    my $tt         = Template->new;
    my $strains_of = {
        S288CvsALL32 => [
            qw{ Spar RM11 YJM789 JAY291 Sigma1278b EC1118 CBS_7960 CLIB215
                CLIB324 FL100 Y10 YJM269 CLIB382 PW5 T7 T73 UC5 AWRI796
                Lalvin_QA23 Vin13 VL3 FostersO FostersB EC9_8 Kyokai_no__7
                AWRI1631 M22 YPS163 DBVPG6765 SK1 Y55 W303
                }
        ],
    };

    my @data;
    for my $dbname ( sort keys %{$strains_of} ) {
        my @strains = @{ $strains_of->{$dbname} };
        my $dbs     = join ',', map {"S288Cvs$_"} @strains;
        my $queries = join ',',
            map { $_ . "query" } ( 1 .. scalar @strains - 1 );
        push @data,
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
perl [% pl_dir %]/alignDB/extra/join_dbs.pl --dbs [% item.dbs %] --goal_db [% item.goal_db %] --outgroup [% item.outgroup %] --target [% item.target %] --queries [% item.queries %] --no_insert=1 --trimmed_fasta=1 --length 1000

perl [% pl_dir %]/alignDB/extra/multi_way_batch.pl -d [% item.goal_db %] -e yeast_65 -f [% data_dir %]/[% item.goal_db %]  -lt 1000 -st 10000 --parallel 4 --run 1-3,21,40

[% END -%]
EOF

    $tt->process( \$text,
        { data => \@data, data_dir => $data_dir, pl_dir => $pl_dir, },
        "auto_yeast65_joins.sh" )
        or die Template->error;
}

{    # multiz
    my $data_dir = File::Spec->catdir( $ENV{HOME}, "data/alignment/yeast65" );
    my $pl_dir   = File::Spec->catdir( $ENV{HOME}, "Scripts" );

    my $tt         = Template->new;
    my $strains_of = {
        S288CvsYJM78Spar => [qw{ Spar YJM789 }],
        S288CvsIII         => [qw{ Spar RM11 YJM789 }],
        S288CvsXVIIIGE10M      => [
            qw{ Spar RM11 YJM789 JAY291 Sigma1278b EC1118 T7 AWRI796
                Lalvin_QA23 Vin13 VL3 FostersO FostersB Kyokai_no__7 DBVPG6765
                SK1 Y55 W303
                }
        ],
        S288CvsXXXII => [
            qw{ Spar RM11 YJM789 JAY291 Sigma1278b EC1118 CBS_7960 CLIB215
                CLIB324 FL100 Y10 YJM269 CLIB382 PW5 T7 T73 UC5 AWRI796
                Lalvin_QA23 Vin13 VL3 FostersO FostersB EC9_8 Kyokai_no__7
                AWRI1631 M22 YPS163 DBVPG6765 SK1 Y55 W303
                }
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
perl [% pl_dir %]/blastz/mz.pl \
    [% FOREACH st IN item.strains -%]
    -d [% data_dir %]/S288Cvs[% st %] \
    [% END -%]
    --tree [% data_dir %]/33way.nwk \
    --out [% data_dir %]/[% item.out_dir %] \
    -syn -p 4

[% END -%]

EOF
    $tt->process(
        \$text,
        {   data     => \@data,
            data_dir => $data_dir,
            pl_dir   => $pl_dir,
        },
        File::Spec->catfile( $store_dir, "auto_yeast65_mz.sh" )
    ) or die Template->error;

    $text = <<'EOF';
#----------------------------#
# maf2fasta
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
perl [% pl_dir %]/alignDB/util/maf2fasta.pl \
    --has_outgroup --id 9606 -p 4 --block \
    -i [% data_dir %]/[% item.out_dir %] \
    -o [% data_dir %]/[% item.out_dir %]_fasta

[% END -%]

#----------------------------#
# mafft
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
perl [% pl_dir %]/alignDB/util/refine_fasta.pl \
    --msa mafft --block -p 4 \
    -i [% data_dir %]/[% item.out_dir %]_fasta \
    -o [% data_dir %]/[% item.out_dir %]_mafft

[% END -%]

#----------------------------#
# muscle-quick
#----------------------------#
[% FOREACH item IN data -%]
# [% item.out_dir %]
perl [% pl_dir %]/alignDB/util/refine_fasta.pl \
    --msa muscle --quick --block -p 4 \
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
        File::Spec->catfile( $store_dir, "auto_yeast65_maf_fasta.sh" )
    ) or die Template->error;
}
