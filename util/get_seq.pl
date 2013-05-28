#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use File::Spec;
use Bio::DB::EUtilities;

my $id  = shift || "NC_001284";
my $dir = shift || ".";

mkdir $dir if !-d $dir;

my @types = qw(gb fasta);

for my $type (@types) {
    my $factory = Bio::DB::EUtilities->new(
        -eutil   => 'efetch',
        -db      => 'nucleotide',
        -rettype => $type,
        -email   => 'mymail@foo.bar',
        -id      => [$id],
    );
    my $file = File::Spec->catfile( $dir, "$id.$type" );
    $file = File::Spec->rel2abs($file);
    print "Saving file to [$file]\n";

    # dump HTTP::Response content to a file (not retained in memory)
    $factory->get_Response( -file => $file );
    print "Done.\n";
}

