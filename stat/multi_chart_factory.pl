#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use FindBin;
use lib "$FindBin::Bin/../lib";
use AlignDB::Excel;
use AlignDB::Stopwatch;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $Config = Config::Tiny->new;
$Config = Config::Tiny->read("$FindBin::Bin/../alignDB.ini");

my $infile        = '';
my $outfile       = '';
my $jc_correction = 0;

my %replace;

my $man  = 0;
my $help = 0;

GetOptions(
    'help|?'    => \$help,
    'man'       => \$man,
    'infile=s'  => \$infile,
    'outfile=s' => \$outfile,
    'jc=s'      => \$jc_correction,
    'replace=s' => \%replace,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

#----------------------------------------------------------#
# Init section
#----------------------------------------------------------#
my $stopwatch = AlignDB::Stopwatch->new;
$stopwatch->start_message("Processing $infile...");

my $excel_obj;
if ($outfile) {
    $excel_obj = AlignDB::Excel->new(
        infile  => $infile,
        outfile => $outfile,
        replace => \%replace,
    );
}
else {
    $excel_obj = AlignDB::Excel->new(
        infile  => $infile,
        replace => \%replace,
    );
    $outfile = $excel_obj->outfile;
}

#----------------------------------------------------------#
# START
#----------------------------------------------------------#
# jc
$excel_obj->jc_correction if $jc_correction;

#----------------------------------------------------------#
# draw charts section
#----------------------------------------------------------#
my @sheet_names = @{ $excel_obj->sheet_names };
{

    #----------------------------#
    # worksheet -- distance_
    #----------------------------#
    my @sheets = grep {/^distance/} @sheet_names;
    foreach (@sheets) {
        my $sheet_name = $_;
        my %option     = (
            chart_serial  => 1,
            x_column      => 1,
            y_column      => 3,
            y_last_column => 6,
            first_row     => 3,
            last_row      => 8,
            x_max_scale   => 5,
            x_title       => "Distance to indels (d1)",
            y_title       => "Nucleotide diversity",
            Height        => 200,
            Width         => 260,
            Top           => 14.25,
            Left          => 650,
        );
        $excel_obj->draw_y( $sheet_name, \%option );

        # chart 2
        $option{chart_serial}++;
        $option{y_column}      = 8;
        $option{y_last_column} = 8;
        $option{y_title}       = "Di/Dn";
        $option{Top} += $option{Height} + 14.25;
        $excel_obj->draw_y( $sheet_name, \%option );
    }
}

{

    #----------------------------#
    # worksheet -- combined_pigccv
    #----------------------------#
    for (qw{combined_pigccv combined_pure_coding combined_pure_noncoding}) {
        my $sheet_name = $_;
        my %option     = (
            chart_serial => 1,
            x_column     => 1,
            y_column     => 2,
            first_row    => 3,
            last_row     => 23,
            x_max_scale  => 20,
            x_title      => "Distance to indels (d1)",
            y_title      => "Nucleotide diversity",
            Height       => 200,
            Width        => 260,
            Top          => 14.25,
            Left         => 650,
        );
        $excel_obj->draw_y( $sheet_name, \%option );

        # chart 2
        $option{chart_serial}++;
        $option{y_column} = 4;
        $option{y_title}  = "GC proportion";
        $option{Top} += $option{Height} + 14.25;
        $excel_obj->draw_y( $sheet_name, \%option );

        # chart 3
        $option{chart_serial}++;
        $option{y_column} = 6;
        $option{y_title}  = "Window CV";
        $option{Top} += $option{Height} + 14.25;
        $excel_obj->draw_y( $sheet_name, \%option );

        # chart 4
        $option{chart_serial}++;
        $option{y_column}  = 4;
        $option{y_title}   = "GC proportion";
        $option{y2_column} = 6;
        $option{y2_title}  = "Window CV";
        $option{Top} += $option{Height} + 14.25;
        $excel_obj->draw_2y( $sheet_name, \%option );
    }
}

{

    #----------------------------#
    # worksheet -- pigccv_freq_
    #----------------------------#
    my @sheets = grep {/^pigccv_freq/} @sheet_names;
    foreach (@sheets) {
        my $sheet_name = $_;
        my %option     = (
            chart_serial => 1,
            x_column     => 1,
            y_column     => 2,
            first_row    => 3,
            last_row     => 8,
            x_max_scale  => 5,
            x_title      => "Distance to indels (d1)",
            y_title      => "Nucleotide diversity",
            Height       => 200,
            Width        => 260,
            Top          => 14.25,
            Left         => 650,
        );
        $excel_obj->draw_y( $sheet_name, \%option );

        # chart 2
        $option{chart_serial}++;
        $option{y_column} = 4;
        $option{y_title}  = "GC proportion";
        $option{Top} += $option{Height} + 14.25;
        $excel_obj->draw_y( $sheet_name, \%option );

        # chart 3
        $option{chart_serial}++;
        $option{y_column} = 6;
        $option{y_title}  = "Window CV";
        $option{Top} += $option{Height} + 14.25;
        $excel_obj->draw_y( $sheet_name, \%option );

        # chart 4
        $option{chart_serial}++;
        $option{y_column}  = 4;
        $option{y_title}   = "GC proportion";
        $option{y2_column} = 6;
        $option{y2_title}  = "Window CV";
        $option{Top} += $option{Height} + 14.25;
        $excel_obj->draw_2y( $sheet_name, \%option );
    }
}

#----------------------------------------------------------#
# POST Processing
#----------------------------------------------------------#
# add time stamp to "basic" sheet
$excel_obj->time_stamp("basic");

# add an index sheet
$excel_obj->add_index_sheet;

print "$outfile has been generated.\n";

$stopwatch->end_message;
exit;

__END__
    
=head1 NAME

    multi_chart_factory.pl - Use Win32::OLE to automate Excel chart

=head1 SYNOPSIS

    multi_chart_factory.pl [options]
      Options:
        --help              brief help message
        --man               full documentation
        --infile            input file name (full path)
        --outfile           output file name
        --jc                Jukes & Cantor correction
        --replace           replace text when charting
                            --replace diversity=divergence

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
