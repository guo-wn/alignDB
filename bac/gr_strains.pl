#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use DBI;
use Text::CSV_XS;
use Bio::Taxon;
use Bio::DB::Taxonomy;
use DateTime::Format::Natural;
use List::MoreUtils qw(any all uniq);

use FindBin;

use AlignDB::Stopwatch;

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
my $gr_dir = $Config->{bac}{gr_dir};
my $bp_dir = $Config->{bac}{bp_dir};
my $td_dir = $Config->{bac}{td_dir};

#my $seq_file    = $Config->{bac}{seq_file};
#my $strain_file = $Config->{bac}{strain_file};
my $strain_file = "gr_strains.csv";

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?' => \$help,
    'man'    => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# init
#----------------------------------------------------------#
$stopwatch->start_message("Writing bac strains summary...");

my $dbh = DBI->connect("DBI:CSV:");

my $taxon_db = Bio::DB::Taxonomy->new(
    -source    => 'flatfile',
    -directory => $td_dir,
    -nodesfile => "$td_dir/nodes.dmp",
    -namesfile => "$td_dir/names.dmp",
);

#----------------------------#
# load tab sep. txt files
#----------------------------#
$dbh->{csv_tables}->{t0} = {
    eol            => "\n",
    sep_char       => "\t",
    file           => "$gr_dir/prokaryotes.txt",
    skip_first_row => 1,
    col_names      => [
        qw{ Organism_Name BioProject_Accession BioProject_ID Group SubGroup Size
            GC Chromosomes_RefSeq Chromosomes_INSDC Plasmids_RefSeq
            Plasmids_INSDC WGS Scaffolds Genes Proteins Release_Date Modify_Date
            Status Center }

    ],
};

$dbh->{csv_tables}->{t1} = {
    eol            => "\n",
    sep_char       => "\t",
    file           => "$bp_dir/summary.txt",
    skip_first_row => 1,
    col_names      => [
        qw{ Organism_Name TaxID Project_Accession Project_ID Project_Type
            Project_Data_Type Date }
    ],
};

#{
#    my $query = qq{
#        SELECT 
#            t0.Status,
#            t0.Scaffolds,
#            count(*)
#        FROM   t0
#        WHERE 1 = 1
#        group by t0.Status, t0.Scaffolds
#        order by t0.Status, t0.Scaffolds
#    };
#    my $sth = $dbh->prepare($query);
#    $sth->execute;
#    my $count;
#    while ( my @row = $sth->fetchrow_array ) {
#        print join("\t", @row, "\n");
#        $count++;
#    }
#    print "count $count\n";
#    
#    exit;
#    1;
#}

#----------------------------#
# join t0 and t1
#----------------------------#
{
    my $query = qq{
        SELECT 
            t1.TaxID,
            t0.Organism_Name,
            t0.BioProject_Accession,
            t0.Group,
            t0.SubGroup,
            t0.Size,
            t0.GC,
            t0.Chromosomes_RefSeq,
            t0.Plasmids_RefSeq,
            t0.WGS,
            t0.Scaffolds,
            t0.Release_Date,
            t0.Status
        FROM   t0, t1
        WHERE 1 = 1
        AND t0.BioProject_Accession = t1.Project_Accession
    };
        #AND t0.Organism_Name = t1.Organism_Name
    my $header_sth = $dbh->prepare($query);
    $header_sth->execute;
    $header_sth->finish;

    # prepare output csv file
    my $csv = Text::CSV_XS->new( { binary => 1, eol => "\n" } );
    open my $csv_fh, ">", $strain_file or die "$strain_file: $!";
    my @cols_name = map { s/^t[01]\.//; $_ } @{ $header_sth->{'NAME'} };
    $csv->print(
        $csv_fh,
        [   @cols_name,
            qw{ species species_id genus genus_id species_member
                genus_species_member genus_strain_member }
        ]
    );

    my @strs = (
        q{ AND t0.Status = 'Complete'
            AND t0.Chromosomes_RefSeq <> '-'
            AND t0.Chromosomes_RefSeq <> ''
            ORDER BY t0.Release_Date },
        q{ AND t0.Status = 'Scaffolds or contigs'
            AND t0.WGS <> '-'
            AND t0.WGS <> ''
            AND t0.Scaffolds <> '-'
            AND t0.Scaffolds <> ''
            AND t0.Scaffolds > 0
            AND t0.Scaffolds < 51
            ORDER BY t0.Release_Date },
    );
    my @taxon_ids;
    for my $str (@strs) {
        my $join_sth = $dbh->prepare( $query . $str );
        $join_sth->execute;
        while ( my @row = $join_sth->fetchrow_array ) {
            for my $item (@row) {
                $item = undef if ( $item eq '-' );
            }

            # find each strains' species and genus
            my $taxon_id = $row[0];
            my $name     = $row[1];

            # dedup, make taxon_id unique
            next if grep { $_ == $row[0] } @taxon_ids;

            my $bac = $taxon_db->get_taxon( -taxonid => $taxon_id );
            if ( !$bac ) {
                warn "Can't find taxon for $name\n";
                next;
            }

            my $species = find_ancestor( $bac, 'species' );
            if ($species) {
                push @row, ( $species->scientific_name, $species->id );
            }
            else {
                warn "Can't find species for $name\n";
                next;
            }

            my $genus = find_ancestor( $bac, 'genus' );
            if ($genus) {
                push @row, ( $genus->scientific_name, $genus->id );
            }
            else {
                warn "Can't find genus for $name\n";
                next;
            }

            push @row, ( undef, undef, undef );    # member numbers

            # write a line
            push @taxon_ids, $row[0];
            $csv->print( $csv_fh, \@row );
        }
        $join_sth->finish;
    }
    close $csv_fh;
}

{
    system "wc -l $_"
        for "$gr_dir/prokaryotes.txt", "$bp_dir/summary.txt", $strain_file;
}

#----------------------------#
# Finish
#----------------------------#
$stopwatch->end_message;
exit;

#----------------------------------------------------------#
# Subroutines
#----------------------------------------------------------#
sub find_ancestor {
    my $taxon = shift;
    my $rank = shift || 'species';

    return $taxon if $taxon->rank eq $rank;

RANK: while (1) {
        $taxon = $taxon->ancestor;
        last RANK unless defined $taxon;
        return $taxon if $taxon->rank eq $rank;
    }

    return;
}

__END__

perl bac_strains.pl 
