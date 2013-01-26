#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use FindBin;
use lib "$FindBin::Bin/../lib";
use AlignDB::WriteExcel;
use AlignDB::Stopwatch;
use AlignDB::Util qw(:all);

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
my $overview_file = "gr_overview.xlsx";

# Database init values
my $server   = $Config->{database}{server};
my $port     = $Config->{database}{port};
my $username = $Config->{database}{username};
my $password = $Config->{database}{password};
my $db       = $Config->{bac}{db};

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'server=s'   => \$server,
    'port=s'     => \$port,
    'db=s'       => \$db,
    'username=s' => \$username,
    'password=s' => \$password,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my @tasks = 1 .. 10;

#----------------------------------------------------------#
# Init section
#----------------------------------------------------------#
$stopwatch->start_message("Overviews for $db...");

my $write_obj = AlignDB::WriteExcel->new(
    mysql   => "$db:$server",
    user    => $username,
    passwd  => $password,
    outfile => $overview_file,
);

#----------------------------------------------------------#
# worksheet -- strains
#----------------------------------------------------------#
my $strains = sub {
    my $sheet_name = 'strains';
    my $sheet;
    my ( $sheet_row, $sheet_col );

    my $sql_query = q{
        SELECT  *
        FROM gr
        WHERE 1 = 1
    };
    {    # write header
        ( $sheet_row, $sheet_col ) = ( 0, 0 );
        my %option = (
            sql_query => $sql_query,
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
        );
        ( $sheet, $sheet_row )
            = $write_obj->write_header_sql( $sheet_name, \%option );
    }

    {    # write contents

        my %option = (
            sql_query => $sql_query,
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
        );
        ($sheet_row) = $write_obj->write_content_direct( $sheet, \%option );
    }

    print "Sheet \"$sheet_name\" has been generated.\n";
};

#----------------------------------------------------------#
# worksheet -- species
#----------------------------------------------------------#
my $species = sub {
    my $sheet_name = 'species';
    my $sheet;
    my ( $sheet_row, $sheet_col );

    my $sql_query = q{
        SELECT  genus_id,
                genus,
                species_id,
                species,
                AVG(genome_size),
                AVG(gc_content),
                species_member,
                genus_species_member,
                genus_strain_member,
                MAX(CHAR_LENGTH(code)) code
        FROM    gr
        WHERE   1 = 1
        GROUP BY species
    };
    {    # write header
        ( $sheet_row, $sheet_col ) = ( 0, 0 );
        my %option = (
            sql_query => $sql_query,
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
        );
        ( $sheet, $sheet_row )
            = $write_obj->write_header_sql( $sheet_name, \%option );
    }

    {    # write contents
        my %option = (
            sql_query => $sql_query,
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
        );
        ($sheet_row) = $write_obj->write_content_direct( $sheet, \%option );
    }

    print "Sheet \"$sheet_name\" has been generated.\n";
};

#----------------------------------------------------------#
# worksheet -- gc_checklist
#----------------------------------------------------------#
my $gc_checklist = sub {
    my $sheet_name = 'gc_checklist';
    my $sheet;
    my ( $sheet_row, $sheet_col );

    {    # write header
        my @headers = qw{
            genus_id genus species_id species avg_genome_size avg_gc count code
        };
        push @headers, "check\ntable", "check\ntree", "check\nalign",
            "check\nxlsx";
        ( $sheet_row, $sheet_col ) = ( 0, 0 );
        my %option = (
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
            header    => \@headers,
        );
        ( $sheet, $sheet_row )
            = $write_obj->write_header_direct( $sheet_name, \%option );
    }

    {    # write contents
        my $sql_query = q{
            SELECT  genus_id,
                    genus,
                    species_id,
                    species,
                    AVG(genome_size),
                    AVG(gc_content),
                    COUNT(*) count,
                    MAX(CHAR_LENGTH(code))
            FROM gr
            WHERE   1 = 1
            AND species_member > 2
            GROUP BY species_id
            ORDER BY species
        };
        my %option = (
            sql_query => $sql_query,
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
        );
        ($sheet_row) = $write_obj->write_content_direct( $sheet, \%option );
    }

    print "Sheet \"$sheet_name\" has been generated.\n";
};

#----------------------------------------------------------#
# worksheet -- gr_gc_checklist
#----------------------------------------------------------#
my $gr_gc_checklist = sub {
    my $sheet_name = 'gr_gc_checklist';
    my $sheet;
    my ( $sheet_row, $sheet_col );

    {    # write header
        my @headers = qw{
            genus_id genus species_id species avg_genome_size avg_gc count code
        };
        push @headers, "check\ntable", "check\ntree", "check\nalign",
            "check\nxlsx";
        ( $sheet_row, $sheet_col ) = ( 0, 0 );
        my %option = (
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
            header    => \@headers,
        );
        ( $sheet, $sheet_row )
            = $write_obj->write_header_direct( $sheet_name, \%option );
    }

    {    # write contents
        my $sql_query = q{
            SELECT  genus_id,
                    genus,
                    species_id,
                    species,
                    AVG(genome_size),
                    AVG(gc_content),
                    COUNT(*) count,
                    MAX(CHAR_LENGTH(code))
            FROM gr
            WHERE   1 = 1
            AND status = 'Complete'
            AND species_member > 2
            GROUP BY species_id
            HAVING count > 2
            ORDER BY species
        };
        my %option = (
            sql_query => $sql_query,
            sheet_row => $sheet_row,
            sheet_col => $sheet_col,
        );
        ($sheet_row) = $write_obj->write_content_direct( $sheet, \%option );
    }

    print "Sheet \"$sheet_name\" has been generated.\n";
};

foreach my $n (@tasks) {
    if ( $n == 1 ) { &$strains;         next; }
    if ( $n == 2 ) { &$species;         next; }
    if ( $n == 3 ) { &$gc_checklist;    next; }
    if ( $n == 4 ) { &$gr_gc_checklist; next; }
}

$stopwatch->end_message;
exit;

__END__

=head1 NAME

    mvar_stat_factory.pl - Generate statistical Excel files from alignDB

=head1 SYNOPSIS

    mvar_stat_factory.pl [options]
     Options:
       --help            brief help message
       --man             full documentation
       --server          MySQL server IP/Domain name
       --db              database name
       --username        username
       --password        password
       --output          output filename
       --run             run special analysis

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do someting
useful with the contents thereof.

=cut
