#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML::Syck qw(Dump Load DumpFile LoadFile);

use File::Find::Rule;
use File::Spec;

use AlignDB::IntSpan;
use AlignDB::Run;
use AlignDB::Stopwatch;

use FindBin;
use lib "$FindBin::Bin/../lib";
use AlignDB;
use AlignDB::Position;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read("$FindBin::Bin/../alignDB.ini");

# Database init values
my $server   = $Config->{database}{server};
my $port     = $Config->{database}{port};
my $username = $Config->{database}{username};
my $password = $Config->{database}{password};
my $db       = $Config->{database}{db};

# write_axt parameter
my $yaml_dir = '.';

# run in parallel mode
my $parallel = 1;

# An align should be an island in the slice
my $want_equal;

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'       => \$help,
    'man'          => \$man,
    'server=s'     => \$server,
    'port=i'       => \$port,
    'db=s'         => \$db,
    'username=s'   => \$username,
    'password=s'   => \$password,
    'y|yaml_dir=s' => \$yaml_dir,
    'want_equal'   => \$want_equal,
    'parallel=i'   => \$parallel,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# Init objects
#----------------------------------------------------------#
my $stopwatch = AlignDB::Stopwatch->new;
$stopwatch->start_message("Write .axt files from $db...");

#----------------------------------------------------------#
# Write .axt files from alignDB
#----------------------------------------------------------#
my @yaml_files
    = File::Find::Rule->file->name( '*.yaml', '*.yml' )->in($yaml_dir);
printf "\n----Total YAML Files: %4s----\n\n", scalar @yaml_files;

for my $yaml_file (sort @yaml_files) {
    print "Loading $yaml_file\n";
    my $base;
    ( undef, undef, $base ) = File::Spec->splitpath($yaml_file);
    $base =~ s/\.(yaml|yml)//;

    if ( $yaml_file =~ /(chr\w+)/ ) {
        my $chr_name  = $1;
        my $runlist   = LoadFile($yaml_file);
        my $slice_set = AlignDB::IntSpan->new($runlist);
        my $outfile   = File::Spec->catfile( $base, "$base.axt" );
        mkdir $base if !-d $base;
        write_slice( $chr_name, $slice_set, $outfile );
    }
    else {
        my $slice_set_of = LoadFile($yaml_file);

        my $worker = sub {
            my $chr_name = shift;
            my $slice_set
                = AlignDB::IntSpan->new( $slice_set_of->{$chr_name} );
            my $outfile = File::Spec->catfile( $base, "$chr_name.axt" );
            mkdir $base if !-d $base;
            write_slice( $chr_name, $slice_set, $outfile );
        };

        my $run = AlignDB::Run->new(
            parallel => $parallel,
            jobs     => [ sort keys %{$slice_set_of} ],
            code     => $worker,
        );
        $run->run;
    }
}

sub write_slice {
    my $chr_name  = shift;
    my $slice_set = shift;
    my $outfile   = shift;

    my $obj = AlignDB->new(
        mysql  => "$db:$server",
        user   => $username,
        passwd => $password,
    );

    # Database handler
    my $dbh = $obj->dbh;

    # position finder
    my $pos_obj = AlignDB::Position->new( dbh => $dbh );

    # get target and query names
    my ( $target_name, $query_name ) = $obj->get_names;

    print "Write slice from $chr_name\n";
    print "Output file is $outfile\n";

    # alignment
    my $align_query = q{
        SELECT t.align_id
        FROM target t, sequence s, chromosome c
        WHERE t.seq_id = s.seq_id
        AND s.chr_id = c.chr_id
        AND c.chr_name = ?
    };
    my $align_sth = $dbh->prepare($align_query);

    # target's chromosomal location
    my $target_query = q{
        SELECT  c.chr_name,
                s.chr_start,
                s.chr_end,
                t.target_seq,
                t.target_runlist
        FROM target t, sequence s, chromosome c
        WHERE t.seq_id = s.seq_id
        AND s.chr_id = c.chr_id
        AND t.align_id = ?
    };
    my $target_sth = $dbh->prepare($target_query);

    # query's chromosomal location
    my $query_query = q{
        SELECT  c.chr_name,
                s.chr_start,
                s.chr_end,
                q.query_seq,
                q.query_runlist,
                q.query_strand
        FROM query q, sequence s, chromosome c
        WHERE q.seq_id = s.seq_id
        AND s.chr_id = c.chr_id
        AND q.align_id = ?
    };
    my $query_sth = $dbh->prepare($query_query);

    my %align_serial;

    # for each align sequence
    $align_sth->execute($chr_name);
    while ( my @row = $align_sth->fetchrow_array ) {
        local $| = 1;
        my ($align_id) = @row;

        print "Processing align_id $align_id\n";

        # target
        $target_sth->execute($align_id);
        my ($target_chr_name, $target_chr_start, $target_chr_end,
            $target_seq,      $target_runlist
        ) = $target_sth->fetchrow_array;

        # query
        $query_sth->execute($align_id);
        my ($query_chr_name, $query_chr_start, $query_chr_end,
            $query_seq,      $query_runlist,   $query_strand
        ) = $query_sth->fetchrow_array;

        my $target_set = AlignDB::IntSpan->new($target_runlist);
        my $query_set  = AlignDB::IntSpan->new($query_runlist);

        my $align_chr_set
            = AlignDB::IntSpan->new("$target_chr_start-$target_chr_end");
        my $iset = $slice_set->intersect($align_chr_set);
        next if $iset->is_empty;

        if ($want_equal) {
            my $start_island = $slice_set->find_islands($target_chr_start);
            if ( !$start_island->equal($align_chr_set) ) {
                print "The align is not equal to one island\n";
                next;
            }
        }

        # there may be two or more subslice intersect this alignment
        for my $ss_set ( $iset->sets ) {

            # rhs position set
            my $ss_start = $pos_obj->at_align( $align_id, $ss_set->min );
            my $ss_end   = $pos_obj->at_align( $align_id, $ss_set->max );
            next if $ss_start >= $ss_end;
            $ss_set = AlignDB::IntSpan->new("$ss_start-$ss_end");
            $ss_set = $ss_set->intersect($target_set);

            next if $ss_set->count <= 1;
            my ( $seg_start, $seg_end ) = ( $ss_set->min, $ss_set->max );
            my $seg_length = $seg_end - $seg_start + 1;

            # prepare axt summary line
            $align_serial{$target_chr_name}++;
            my $serial = $align_serial{$target_chr_name} - 1;

            # align coordinates to target & query chromosome coordinates
            my $target_seg_start
                = $pos_obj->at_target_chr( $align_id, $seg_start );
            my $target_seg_end
                = $pos_obj->at_target_chr( $align_id, $seg_end );
            my $query_seg_start
                = $pos_obj->at_query_chr( $align_id, $seg_start );
            my $query_seg_end = $pos_obj->at_query_chr( $align_id, $seg_end );
            if ( $query_strand eq '-' ) {
                ( $query_seg_start, $query_seg_end )
                    = ( $query_seg_end, $query_seg_start );
            }
            my $score = $seg_length * 100;    # sham score

            # append axt file
            {
                print "Append axt files: "
                    . "$target_chr_name:$target_seg_start-$target_seg_end"
                    . "\n";
                open my $outfh, '>>', $outfile;
                print {$outfh} "$serial";
                print {$outfh} " $target_chr_name";
                print {$outfh} " $target_seg_start $target_seg_end";
                print {$outfh} " $query_chr_name";
                print {$outfh} " $query_seg_start $query_seg_end";
                print {$outfh} " $query_strand $score\n";
                print {$outfh}
                    substr( $target_seq, $seg_start - 1, $seg_length ), "\n";
                print {$outfh}
                    substr( $query_seq, $seg_start - 1, $seg_length ), "\n";
                print {$outfh} "\n";
                close $outfh;
            }
        }
        print "  finish write axt file\n";
    }
}

$stopwatch->end_message;

__END__

=head1 NAME

    write_axt_slice.pl - extract alignment slices from alignDB

=head1 SYNOPSIS

    write_axt_slice.pl [options]
      Options:
        --help              brief help message
        --man               full documentation
        --server            MySQL server IP/Domain name
        --db                database name
        --username          username
        --password          password
        -y, --yaml_dir      dir of yaml

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

format 1: chr1.yml
  --- 1-25744,815056-817137
  
  output axt: chr1/chr1.axt
format 2: bin1.yml
  ---
  chr1: '1-25744,815056-817137'

  output axt: bin1/chr1.axt


=cut

