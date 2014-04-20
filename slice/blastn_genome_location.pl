#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long;
use Pod::Usage;
use Config::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

use File::Basename;
use Bio::SearchIO;
use Set::Scalar;

use AlignDB::IntSpan;
use AlignDB::Stopwatch;

use FindBin;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
# record ARGV and Config
my $stopwatch = AlignDB::Stopwatch->new(
    program_name => $0,
    program_argv => [@ARGV],
);

my $file;
my $alignment_view = 0;    # blastall -m

my $identity = 90;
my $coverage = 0.9;

my $output;

my $man  = 0;
my $help = 0;

$|++;

GetOptions(
    'help|?'       => \$help,
    'man|m'        => \$man,
    'f|file=s'     => \$file,
    'm|view=s'     => \$alignment_view,
    'i|identity=i' => \$identity,
    'c|coverage=f' => \$coverage,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my $view_name = {
    0 => "blast",         # Pairwise
    7 => "blastxml",      # BLAST XML
    9 => "blasttable",    # Hit Table
};

my $result_format = $view_name->{$alignment_view};

#----------------------------------------------------------#
# init
#----------------------------------------------------------#
$stopwatch->start_message("Find paralog...");

if ( !$output ) {
    $output = basename($file);
    ($output) = grep {defined} split /\./, $output;
    $output = "$output.gl.fasta";
}

#----------------------------------------------------------#
# load blast reports
#----------------------------------------------------------#
print "load blast reports\n";
open my $blast_fh, '<', $file;

my %seq_of;    # store sequences of genome locations

my $searchio = Bio::SearchIO->new(
    -format => $result_format,
    -fh     => $blast_fh,
);

QUERY: while ( my $result = $searchio->next_result ) {
    my $query_name   = $result->query_name;
    my $query_length = $result->query_length;
    print " " x 4, "name: $query_name\tlength: $query_length\n";
    while ( my $hit = $result->next_hit ) {
        my $hit_name = $hit->name;

        while ( my $hsp = $hit->next_hsp ) {
            my $query_set = AlignDB::IntSpan->new;

            # process the Bio::Search::HSP::HSPI object
            my $hsp_length = $hsp->length( ['query'] );

            # use "+" for default strand
            # -1 = Minus strand, +1 = Plus strand
            my ( $query_strand, $hit_strand ) = $hsp->strand("list");
            my $hsp_strand = "+";
            if ( $query_strand + $hit_strand == 0 and $query_strand != 0 ) {
                $hsp_strand = "-";
            }

            my $align_obj = $hsp->get_aln;    # a Bio::SimpleAlign object
            my ($query_obj) = $align_obj->each_seq_with_id($query_name);
            my ($hit_obj)   = $align_obj->each_seq_with_id($hit_name);

            my $q_start = $query_obj->start;
            my $q_end   = $query_obj->end;
            if ( $q_start > $q_end ) {
                ( $q_start, $q_end ) = ( $q_end, $q_start );
            }
            $query_set->add_range( $q_start, $q_end );

            my $h_start = $hit_obj->start;
            my $h_end   = $hit_obj->end;
            if ( $h_start > $h_end ) {
                ( $h_start, $h_end ) = ( $h_end, $h_start );
            }

            my $query_coverage = $query_set->size / $query_length;
            my $hsp_identity   = $hsp->percent_identity;

            if ( $query_coverage >= $coverage and $hsp_identity >= $identity ) {
                my $head = "$hit_name(+):$h_start-$h_end";
                if ( !exists $seq_of{$head} ) {
                    my $seq = $hit_obj->seq;
                    $seq =~ tr/-//d;
                    $seq = uc $seq;
                    if ( $hsp_strand ne "+" ) {
                        $seq = revcom($seq);
                    }
                    $seq_of{$head} = $seq;
                }
            }
        }
    }
}

close $blast_fh;

#----------------------------------------------------------#
# write fasta
#----------------------------------------------------------#
{
    #----------------------------#
    # remove locations fully contained by others
    #----------------------------#
    print "Merge nested locations\n";
    my %chrs;
    my %set_of;
    for my $node ( keys %seq_of ) {
        my ( $chr, $set, $strand ) = string_to_set($node);
        $chrs{$chr}++;
        $set_of{$node} = { chr => $chr, set => $set };
    }

    my $to_remove = Set::Scalar->new;
    for my $chr ( sort keys %chrs ) {
        my @nodes = sort grep { $set_of{$_}->{chr} eq $chr } keys %seq_of;

        for my $i ( 0 .. $#nodes ) {
            my $node_i = $nodes[$i];
            my $set_i  = $set_of{$node_i}->{set};
            for my $j ( $i + 1 .. $#nodes ) {
                my $node_j = $nodes[$j];
                my $set_j  = $set_of{$node_j}->{set};

                if ( $set_i->larger_than($set_j) ) {
                    $to_remove->insert($node_j);
                }
                elsif ( $set_j->larger_than($set_i) ) {
                    $to_remove->insert($node_i);
                }
            }
        }
    }

    #----------------------------#
    # sort heads
    #----------------------------#
    print "Sort locations\n";
    my @sorted = map { $to_remove->has($_) ? () : $_ } keys %seq_of;

    # start point on chromosomes
    @sorted = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { /[\w.]+\(.\)\:(\d+)/; [ $_, $1 ] } @sorted;

    # chromosome name
    @sorted = map { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
        map { /([\w.]+)\(.\)\:/; [ $_, $1 ] } @sorted;

    print "Write outputs\n";
    open my $out_fh, ">", $output;
    for my $head (@sorted) {
        print {$out_fh} ">$head\n";
        print {$out_fh} $seq_of{$head}, "\n";
    }
    close $out_fh;
}

$stopwatch->end_message;

exit;

#----------------------------------------------------------#
# Subroutines
#----------------------------------------------------------#
sub string_to_set {
    my $node = shift;

    my ( $chr, $runlist ) = split /:/, $node;
    my $strand = "+";
    if ( $chr =~ /\((.+)\)/ ) {
        $strand = $1;
        $chr =~ s/\(.+\)//;
    }
    my $set = AlignDB::IntSpan->new($runlist);

    return ( $chr, $set, $strand );
}

sub revcom {
    my $seq = shift;

    $seq =~ tr/ACGTMRWSYKVHDBNacgtmrwsykvhdbn-/TGCAKYWSRMBDHVNtgcakyswrmbdhvn-/;
    my $seq_rc = reverse $seq;

    return $seq_rc;
}

__END__

=head1 NAME

    update_align_paralog.pl - Add additional paralog info to alignDB
    
=head1 SYNOPSIS

    update_align_paralog.pl [options]
      Options:
        --help               brief help message
        --man                full documentation
        --server             MySQL server IP/Domain name
        --db                 database name
        --username           username
        --password           password
        --datalib|da         blast database
        --megablast|mega     use megablast or not
        --view|v             blast output format

    update_align_paralog.pl -d=Nipvs9311 -da=nip_chro --mega=1 -v=9

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

