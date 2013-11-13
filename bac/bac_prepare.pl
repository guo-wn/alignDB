#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use DBI;
use File::Find::Rule;
use File::Spec;
use File::Copy;
use File::Basename;
use Text::Table;
use List::MoreUtils qw(uniq);
use Archive::Extract;

use Bio::Taxon;
use Bio::DB::Taxonomy;
use Template;

use AlignDB::IntSpan;
use AlignDB::Stopwatch;

use FindBin;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read("$FindBin::Bin/../alignDB.ini");

# record ARGV and Config
my $stopwatch = AlignDB::Stopwatch->new(
    program_name => $0,
    program_argv => [@ARGV],
    program_conf => $Config,
);

# running options
my $base_dir    = $Config->{bac}{base_dir};
my $taxon_dir   = $Config->{bac}{taxon_dir};
my $seq_dir     = "/home/wangq/data/bacteria/bac_seq_dir";
my $working_dir = ".";

my $parent_id = "562,585054";    # E.coli and E. fergusonii
my $target_id;
my $outgroup_id;
my $exclude_ids = '0';

# use custom name_str
# working dir and goal db name
# mysql restrict db name length 64
my $name_str;

# Database init values
my $server   = $Config->{database}{server};
my $port     = $Config->{database}{port};
my $username = $Config->{database}{username};
my $password = $Config->{database}{password};
my $db       = $Config->{bac}{db};
my $db_gr    = $Config->{bac}{db_gr};

my $gr;
my $scaffold;
my $td_dir   = $Config->{bac}{td_dir};      # taxdmp
my $nb_dir   = $Config->{bac}{nb_dir};      # NCBI genomes bac
my $nbd_dir  = $Config->{bac}{nbd_dir};     # NCBI genomes bac draft
my $ngbd_dir = $Config->{bac}{ngbd_dir};    # NCBI genbank genomes bac draft

# run in parallel mode
my $parallel = $Config->{generate}{parallel};

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'          => \$help,
    'man'             => \$man,
    'server=s'        => \$server,
    'port=i'          => \$port,
    'username=s'      => \$username,
    'password=s'      => \$password,
    'd|db=s'          => \$db,
    'db_gr=s'         => \$db_gr,
    'b|base_dir=s'    => \$base_dir,
    'x|taxon_dir=s'   => \$taxon_dir,
    'w|working_dir=s' => \$working_dir,
    'p|parent_id=s'   => \$parent_id,
    't|target_id=i'   => \$target_id,
    'o|r|outgroup=i'  => \$outgroup_id,
    'e|exclude=s'     => \$exclude_ids,
    'n|name_str=s'    => \$name_str,
    'gr'              => \$gr,
    'scaffold'        => \$scaffold,
    'parallel=i'      => \$parallel,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# init
#----------------------------------------------------------#
$stopwatch->start_message("Preparing whole species");

my $dbh = DBI->connect( "dbi:mysql:" . ( $gr ? $db_gr : $db ) . ":$server",
    $username, $password );

my $id_str;
{    # expand $parent_id
    $taxon_dir = $td_dir if $gr;

    my $taxon_db = Bio::DB::Taxonomy->new(
        -source    => 'flatfile',
        -directory => $taxon_dir,
        -nodesfile => "$taxon_dir/nodes.dmp",
        -namesfile => "$taxon_dir/names.dmp",
    );
    my @parent_ids = split /,/, $parent_id;

    my $sub_id_set = AlignDB::IntSpan->new;
    for my $p_id (@parent_ids) {
        $sub_id_set->add($p_id);
        my $parent = $taxon_db->get_taxon( -taxonid => $p_id );

        my @taxa = $taxon_db->get_all_Descendents($parent);
        for my $taxon (@taxa) {
            $sub_id_set->add( $taxon->id );
        }
    }

    my $db_id_set = AlignDB::IntSpan->new;
    {
        my $query
            = $gr
            ? $scaffold
                ? q{ SELECT taxonomy_id FROM gr WHERE 1 = 1 }
                : q{ SELECT taxonomy_id FROM gr WHERE status = 'Complete' }
            : q{ SELECT taxonomy_id FROM strain WHERE seq_ok = 1 };
        my $sth = $dbh->prepare($query);
        $sth->execute;
        while ( my ($id) = $sth->fetchrow_array ) {
            $db_id_set->add($id);
        }
    }

    my $id_set = $sub_id_set->intersect($db_id_set);
    $id_set->remove( split /,/, $exclude_ids );
    $id_str = '(' . ( join ",", $id_set->as_array ) . ')';

    die "Wrong id_str $id_str\n" unless $id_str =~ /\d+/;
}

{    # making working dir
    if ( !$name_str ) {
        my $query
            = $gr
            ? qq{ SELECT DISTINCT species FROM gr WHERE taxonomy_id IN $id_str }
            : qq{ SELECT DISTINCT species FROM strain st WHERE st.taxonomy_id IN $id_str };
        my $sth = $dbh->prepare($query);
        $sth->execute;

        while ( my ($name) = $sth->fetchrow_array ) {
            $name_str .= "_$name";
        }
        $name_str =~ s/\W/_/g;
        $name_str =~ s/^_+//g;
        $name_str =~ s/\s+/_/g;
    }

    print "Working on $name_str\n";
    $working_dir = File::Spec->catdir( $working_dir, $name_str );
    $working_dir = File::Spec->rel2abs($working_dir);
    mkdir $working_dir unless -e $working_dir;
    print "Working dir is $working_dir\n";
}

my @query_ids;
{    # find all strains' taxon ids

    # select all strains in this species
    my $query
        = $gr
        ? qq{ SELECT taxonomy_id, organism_name, released_date, status, code FROM gr WHERE taxonomy_id IN $id_str ORDER BY released_date, status, code }
        : qq{ SELECT taxonomy_id, organism_name, released_date FROM strain WHERE taxonomy_id IN $id_str ORDER BY released_date };
    my $sth = $dbh->prepare($query);
    $sth->execute;

    # header line
    my @strains;
    my $table = Text::Table->new( @{ $sth->{NAME} } );
    while ( my @row = $sth->fetchrow_array ) {
        push @strains, [@row];
        $table->load( [@row] );
    }

    my $table_file = File::Spec->catfile( $working_dir, "table.txt" );
    open my $fh, '>', $table_file;
    print {$fh} $table, "\n";
    print $table, "\n";

    {
        my $message = "There are " . scalar @strains . " strains\n";
        print {$fh} $message;
        print $message;
    }

    if ($target_id) {
        my ($exist) = grep { $_->[0] == $target_id } @strains;
        if ( defined $exist ) {
            my $message = "Use [$exist->[1]] as target, as you wish.\n";
            print {$fh} $message;
            print $message;
        }
        else {
            print "Taxon $target_id doesn't exist, please check.\n";
            exit;
        }
    }
    else {
        $target_id = $strains[0]->[0];
        my $message
            = "Use [$strains[0]->[1]] as target, the oldest strain on NCBI.\n";
        print {$fh} $message;
        print $message;
    }

    @query_ids = map { $_->[0] == $target_id ? () : $_->[0] } @strains;

    if ($outgroup_id) {
        my ($exist) = grep { $_ == $outgroup_id } @query_ids;
        if ( defined $exist ) {
            my $message = "Use [$exist] as reference, as you wish.\n";
            print {$fh} $message;
            print $message;

            # make $outgroup_id first
            @query_ids = map { $_ == $outgroup_id ? () : $_ } @query_ids;
            unshift @query_ids, $outgroup_id;
        }
        else {
            print "Taxon $outgroup_id doesn't exist, please check.\n";
        }
    }

    print "\n";
    print {$fh} "perl " . $stopwatch->cmd_line, "\n";

    close $fh;
}

{    # build fasta files

    $base_dir = $nb_dir if $gr;

    # read all filenames, then grep
    print "Reading file list\n";
    my @fna_files = File::Find::Rule->file->name('*.fna')->in($base_dir);
    my @gff_files = File::Find::Rule->file->name('*.gff')->in($base_dir);
    my ( @scaff_files, @contig_files );
    if ( $gr and $scaffold ) {
        @scaff_files
            = File::Find::Rule->file->name('*.scaffold.fna.tgz')->in($nbd_dir);
        @contig_files
            = File::Find::Rule->file->name('*.contig.fna.tgz')->in($ngbd_dir);
    }

    print "Rewrite seqs for every strains\n";
    for my $taxon_id ( $target_id, @query_ids ) {
        print "taxon_id $taxon_id\n";
        my $id_dir = File::Spec->catdir( $seq_dir, $taxon_id );
        mkdir $id_dir unless -e $id_dir;

        my @accs;    # complete accessions

        if ( !$gr ) {
            my $query
                = qq{ SELECT accession FROM seq WHERE taxonomy_id = ? AND replicon like "%chr%" };
            my $sth = $dbh->prepare($query);
            $sth->execute($taxon_id);
            while ( my ($acc) = $sth->fetchrow_array ) {
                push @accs, $acc;
            }
        }
        else {
            my $query = qq{ SELECT chr_refseq FROM gr WHERE taxonomy_id = ? };
            my $sth   = $dbh->prepare($query);
            $sth->execute($taxon_id);
            my ($acc) = $sth->fetchrow_array;
            push @accs,
                ( map { s/\.\d+$//; $_ } grep {defined} ( split /,/, $acc ) );
        }

        # for NZ_CM*** accessions, the following prep_fa() will find nothing
        # AND is $scaffold, prep_scaff() will find the scaffolds
        for my $acc ( grep {defined} @accs ) {
            my ($fna_file) = grep {/$acc/} @fna_files;
            copy( $fna_file, $id_dir );

            my ($gff_file) = grep {/$acc/} @gff_files;
            copy( $gff_file, $id_dir );
        }

        if ($scaffold) {
            my ($wgs) = get_taxon_wgs( $dbh, $taxon_id );

            next unless $wgs;

            $wgs =~ s/\d+$//;
            my $rc = prep_scaff( \@scaff_files, "NZ_$wgs", $id_dir );
            if ($rc) {
                warn " " x 4, $rc;
                print " " x 4, "Try contig files\n";
                my $rc2 = prep_scaff( \@contig_files, $wgs, $id_dir );
                warn " " x 4, $rc2 if $rc2;
            }
        }
    }
}

{

    my $tt = Template->new;
    my $text;

    # taxon.csv
    $text = <<'EOF';
#!/bin/bash

cd [% working_dir %]

perl [% findbin %]/../taxon/strain_info.pl \
    --file [% working_dir %]/info.csv \
[% FOREACH id IN query_ids -%]
    --id [% id %] \
[% END -%]
    --id [% target_id %]

perl [% findbin %]/../taxon/strain_bz.pl \
    --file [% working_dir %]/info.csv \
    -w [% working_dir %]/.. \
    --seq_dir [% seq_dir %] \
    --name [% name_str %] \
[% FOREACH id IN query_ids -%]
    -q [% id %] \
[% END -%]
    -t [% target_id %]

    
    
EOF
    $tt->process(
        \$text,
        {   findbin     => $FindBin::Bin,
            working_dir => $working_dir,
            seq_dir     => $seq_dir,
            name_str    => $name_str,
            target_id   => $target_id,
            query_ids   => \@query_ids,
        },
        File::Spec->catfile( $working_dir, "prepare.sh" )
    ) or die Template->error;

}

$stopwatch->end_message;
exit;

sub prep_fa {
    my $all_files = shift;
    my $acc       = shift;
    my $dir       = shift;

    my ($fna_file) = grep {/$acc/} @{$all_files};
    if ( !$fna_file ) {
        return "Can't find fasta file for $acc\n";
    }

    my $fa_file = File::Spec->catfile( $dir, "$acc.fa" );
    open my $in_fh,  '<', $fna_file;
    open my $out_fh, '>', $fa_file;
    while (<$in_fh>) {
        if (/>/) {
            print {$out_fh} ">$acc\n";
        }
        else {
            print {$out_fh} $_;
        }
    }
    close $out_fh;
    close $in_fh;

    return;
}

sub get_taxon_wgs {
    my $dbh      = shift;
    my $taxon_id = shift;

    my $query = qq{ SELECT wgs FROM gr WHERE taxonomy_id = ? };
    my $sth   = $dbh->prepare($query);
    $sth->execute($taxon_id);
    my ($wgs) = $sth->fetchrow_array;

    return $wgs;
}

sub prep_scaff {
    my $all_files = shift;
    my $wgs       = shift;
    my $dir       = shift;

    my ($wgs_file) = grep {/$wgs/} @{$all_files};
    if ( !$wgs_file ) {
        return "Can't find fasta file for $wgs\n";
    }

    my $ae = Archive::Extract->new( archive => $wgs_file );
    my $ok = $ae->extract( to => $dir );

    if ( !$ok ) {
        return $ae->error;
    }

    my (@files) = map { File::Spec->rel2abs( $_, $dir ) } @{ $ae->files };

    for my $file (@files) {
        unless ( -e $file ) {
            return "$file not exists!\n";
        }
        if ( ( stat($file) )[7] < 1024 ) {
            next;
        }

        my $basename = basename( $file, ".fna" );
        my $fa_file = File::Spec->catfile( $dir, "$basename.fa" );
        copy( $file, $fa_file );
    }

    unlink $_ for @files;

    return;
}

__END__

perl bac_bz.pl --base_dir d:\bacteria\bacteria_101015 --parent 562
perl d:/wq/Scripts/tool/replace.pl -d d:/wq/Scripts/alignDB/bac -p "cmd.bat" -f /home/wangq -r d:/wq
