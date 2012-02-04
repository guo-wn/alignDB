#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use YAML qw(Dump Load DumpFile LoadFile);

use File::Find::Rule;
use File::Basename;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use List::MoreUtils qw(any all);

use AlignDB::IntSpan;
use AlignDB::Stopwatch;
use AlignDB::Util qw(:all);
use AlignDB::Run;

use FindBin;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $in_dir           = '.';           # Specify location here
my $out_dir          = undef;         # Specify output dir here
my $length_threshold = 1000;          # Set the threshold of alignment length
my $aln_prog         = 'clustalw';    # Default alignment program

my $quick_mode   = undef;    # quick mode
my $indel_expand = 50;       # in quick mode, expand indel regoin
my $indel_join   = 50;       # in quick mode, join adjacent indel regions

my $no_trim = 0;             # trim outgroup only sequence

# run in parallel mode
my $parallel = 1;

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'in_dir=s'   => \$in_dir,
    'out_dir=s'  => \$out_dir,
    'length=i'   => \$length_threshold,
    'msa=s'      => \$aln_prog,
    'quick'      => \$quick_mode,
    'no_trim'    => \$no_trim,
    'expand=i'   => \$indel_expand,
    'join=i'     => \$indel_join,
    'parallel=i' => \$parallel,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# make output dir
#----------------------------------------------------------#
unless ($out_dir) {
    $out_dir = $in_dir . "_$aln_prog";
    $out_dir = $out_dir . "_quick" if $quick_mode;
}
unless ( -e $out_dir ) {
    mkdir $out_dir, 0777
        or die "Cannot create \"$out_dir\" directory: $!";
}

#----------------------------------------------------------#
# Search for all files and push their paths to @dir_fiels
#----------------------------------------------------------#
my @files
    = File::Find::Rule->file()->name( '*.fa', '*.fas', '*.fasta' )->in($in_dir);
printf "\n----Total .fasta Files: %4s----\n\n", scalar @files;

#----------------------------------------------------------#
# realign
#----------------------------------------------------------#
my $worker = sub {
    my $infile = shift;

    my $stopwatch = AlignDB::Stopwatch->new;
    print "Process $infile\n";

    my ( $seq_of, $seq_names ) = read_fasta($infile);

    if ($quick_mode) {
        $seq_of = realign_quick( $seq_of, $seq_names );
    }
    else {
        $seq_of = realign_all( $seq_of, $seq_names );
    }

    $seq_of = trim_hf( $seq_of, $seq_names );

    if ( !$no_trim ) {
        $seq_of = trim_outgroup( $seq_of, $seq_names );
    }

    my $outfile = basename($infile);
    $outfile = $out_dir . "/$outfile";

    open my $out_fh, '>', $outfile
        or die("Cannot open OUT file $outfile");
    for my $name ( @{$seq_names} ) {
        my $seq = $seq_of->{$name};
        print {$out_fh} ">", $name, "\n";
        print {$out_fh} $seq, "\n";
    }
    close $out_fh;
};

# process each .fasta files
my $stopwatch = AlignDB::Stopwatch->new;

my @jobs = sort @files;
my $run  = AlignDB::Run->new(
    parallel => $parallel,
    jobs     => \@jobs,
    code     => $worker,
);
$run->run;

$stopwatch->block_message( "All files have been processed.", "duration" );
exit;

#----------------------------#
# realign all seqs
#----------------------------#
sub realign_all {
    my $seq_of    = shift;
    my $seq_names = shift;

    my @seqs;
    for ( @{$seq_names} ) {
        push @seqs, $seq_of->{$_};
    }

    my $realigned_seqs = multi_align( \@seqs, $aln_prog );

    for my $i ( 0 .. scalar @{$seq_names} - 1 ) {
        $seq_of->{ $seq_names->[$i] } = $realigned_seqs->[$i];
    }

    return $seq_of;
}

#----------------------------#
# realign indel_flank region
#----------------------------#
sub realign_quick {
    my $seq_of    = shift;
    my $seq_names = shift;

    # use AlignDB::IntSpan to find nearby indels
    #   expand indel by a range of $indel_expand
    my %indel_sets;
    for (@$seq_names) {
        $indel_sets{$_} = find_indel_set( $seq_of->{$_}, $indel_expand );
    }

    my $realign_region = AlignDB::IntSpan->new;
    my $combinat       = Math::Combinatorics->new(
        count => 2,
        data  => $seq_names,
    );
    while ( my @combo = $combinat->next_combination ) {
        my $intersect_set = AlignDB::IntSpan->new;
        my $union_set     = AlignDB::IntSpan->new;
        $intersect_set
            = $indel_sets{ $combo[0] }->intersect( $indel_sets{ $combo[1] } );
        $union_set
            = $indel_sets{ $combo[0] }->union( $indel_sets{ $combo[1] } );

        for my $span ( $union_set->runlists ) {
            my $flag_set = $intersect_set->intersect($span);
            if ( $flag_set->is_not_empty ) {
                $realign_region->add($span);
            }
        }
    }

    # join adjacent realign regions
    $realign_region = $realign_region->join_span($indel_join);

    # realign all segments in realign_region
    my @realign_region_spans = $realign_region->spans;
    for ( reverse @realign_region_spans ) {
        my $seg_start = $_->[0];
        my $seg_end   = $_->[1];
        my @segments;
        for (@$seq_names) {
            my $seg = substr(
                $seq_of->{$_},
                $seg_start - 1,
                $seg_end - $seg_start + 1
            );
            push @segments, $seg;
        }

        my $realign_segments = multi_align( \@segments, $aln_prog );

        for (@$seq_names) {
            my $seg = shift @$realign_segments;
            substr(
                $seq_of->{$_},
                $seg_start - 1,
                $seg_end - $seg_start + 1, $seg
            );
        }
    }

    return $seq_of;
}

#----------------------------#
# trim header and footer indels
#----------------------------#
sub trim_hf {
    my $seq_of    = shift;
    my $seq_names = shift;

    # header indels
    while (1) {
        my @first_column;
        for ( @{$seq_names} ) {
            my $first_base = substr( $seq_of->{$_}, 0, 1 );
            push @first_column, $first_base;
        }
        if ( any { $_ eq '-' } @first_column ) {
            for ( @{$seq_names} ) {
                substr( $seq_of->{$_}, 0, 1, '' );
            }
        }
        else {
            last;
        }
    }

    # footer indels
    while (1) {
        my (@last_column);
        for ( @{$seq_names} ) {
            my $last_base = substr( $seq_of->{$_}, -1, 1 );
            push @last_column, $last_base;
        }
        if ( any { $_ eq '-' } @last_column ) {
            for ( @{$seq_names} ) {
                substr( $seq_of->{$_}, -1, 1, '' );
            }
        }
        else {
            last;
        }
    }

    return $seq_of;
}

#----------------------------#
# trim outgroup only sequence
#----------------------------#
# if intersect is superset of union
#   ref    GAAAAC
#   target G----C
#   query  G----C
sub trim_outgroup {
    my $seq_of    = shift;
    my $seq_names = shift;

    # don't expand indel set
    my %indel_sets;
    for ( 1 .. @$seq_names - 1 ) {
        my $name = $seq_names->[$_];
        $indel_sets{$name} = find_indel_set( $seq_of->{$name} );
    }

    # find trim_region
    my $trim_region = AlignDB::IntSpan->new;

    my $union_set     = AlignDB::IntSpan::union( values %indel_sets );
    my $intersect_set = AlignDB::IntSpan::intersect( values %indel_sets );

    for my $span ( $union_set->runlists ) {
        if ( $intersect_set->superset($span) ) {
            $trim_region->add($span);
        }
    }

    # trim all segments in trim_region
    for ( reverse $trim_region->spans ) {
        my $seg_start = $_->[0];
        my $seg_end   = $_->[1];
        for (@$seq_names) {
            substr(
                $seq_of->{$_},
                $seg_start - 1,
                $seg_end - $seg_start + 1, ''
            );
        }
    }

    return $seq_of;
}

__END__

=head1 NAME

    refine_fasta.pl - realign fasta file

=head1 SYNOPSIS
    perl refine_fasta.pl --in_dir G:/S288CvsRM11 --msa muscle --quick

    refine_fasta.pl [options]
      Options:
        --help              brief help message
        --man               full documentation
        --in_dir            fasta files' location
        --out_dir           output location
        --length            length threshold
        --msa               alignment program
        --quick             use quick mode
        --no_trim           don't trim outgroup sequence (the first one)
        --expand            in quick mode, expand indel region
        --join              in quick mode, join adjacent indel regions
        --parallel          run in parallel mode

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do someting
useful with the contents thereof.

=cut