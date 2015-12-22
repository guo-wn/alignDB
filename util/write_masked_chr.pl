#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long qw(HelpMessage);
use Config::Tiny;
use FindBin;
use YAML::Syck qw(Dump Load DumpFile LoadFile);

use File::Find::Rule;
use File::Basename;
use String::Compare;
use List::MoreUtils qw(zip);
use Set::Scalar;

use MCE::Flow;

use AlignDB::IntSpan;
use AlignDB::Stopwatch;
use AlignDB::Util qw(:all);

use lib "$FindBin::RealBin/../lib";
use AlignDB::Ensembl;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#
my $Config = Config::Tiny->read("$FindBin::RealBin/../alignDB.ini");

# record ARGV and Config
my $stopwatch = AlignDB::Stopwatch->new(
    program_name => $0,
    program_argv => [@ARGV],
    program_conf => $Config,
);

=head1 NAME

write_masked_chr.pl - just like RepeatMasker does, but use ensembl annotations.
                      And it change fasta headers for you.

=head1 SYNOPSIS

    perl write_masked_chr.pl [options]
      Options:
        --help              brief help message
        --man               full documentation
        --server            MySQL server IP/Domain name
        --username          username
        --password          password
        --ensembl           ensembl database name
        --feature           mask which feature, default is "repeat"
        -y, --yaml_file     use a exists yaml file as annotation
        --dir               .fa dir
    
    > perl write_masked_chr.pl -e arabidopsis_58 
    > perl write_masked_chr.pl --dir e:\data\alignment\arabidopsis\ath_58\ -y e:\wq\Scripts\alignDB\util\arabidopsis_58_repeat.yml
    
    $ perl write_masked_chr.pl -e nip_65
    $ perl write_masked_chr.pl --dir /home/wangq/data/alignment/rice/nip_65 -y nip_65_repeat.yml

=cut

my $linelen = 60;

GetOptions(
    'help|?' => sub { HelpMessage(0) },
    'server|s=s'   => \( my $server   = $Config->{database}{server} ),
    'port|P=i'     => \( my $port     = $Config->{database}{port} ),
    'username|u=s' => \( my $username = $Config->{database}{username} ),
    'password|p=s' => \( my $password = $Config->{database}{password} ),
    'ensembl|e=s'  => \my $ensembl_db,
    'feature=s'    => \( my $feature  = "repeat" ),
    'yaml_file|y=s' => \my $yaml_file,
    'dir=s'         => \my $dir_fa,
    'parallel=i'    => \( my $parallel = $Config->{generate}{parallel} ),
) or HelpMessage(1);

#----------------------------------------------------------#
# Init objects
#----------------------------------------------------------#
$stopwatch->start_message("Write masked chr...");

#----------------------------#
# Get runlist of $feature
#----------------------------#
my $ftr_of = {};

if ($yaml_file) {
    $ftr_of = LoadFile($yaml_file);
}
else {

    # ensembl handler
    my $ensembl = AlignDB::Ensembl->new(
        server => $server,
        db     => $ensembl_db,
        user   => $username,
        passwd => $password,
    );

    # ensembl handler
    my $db_adaptor = $ensembl->db_adaptor;

    my $slice_adaptor = $db_adaptor->get_SliceAdaptor;
    my @slices        = @{ $slice_adaptor->fetch_all('chromosome') };
    my @chrs
        = sort { $a->{chr_name} cmp $b->{chr_name} }
        map { { chr_name => $_->seq_region_name, chr_start => $_->start, chr_end => $_->end, } }
        @slices;

    my $worker = sub {
        my ( $self, $chunk_ref, $chunk_id ) = @_;
        my $chr = $chunk_ref->[0];

        my $chr_runlist = $chr->{chr_start} . "-" . $chr->{chr_end};
        printf "%s:%s\n", $chr->{chr_name}, $chr_runlist;

        eval { $ensembl->set_slice( $chr->{chr_name}, $chr->{chr_start}, $chr->{chr_end} ); };
        if ($@) {
            warn "Can't get annotation\n";
            return;
        }

        my $slice       = $ensembl->slice;
        my $ftr_chr_set = $slice->{"_$feature\_set"};

        MCE->gather( $chr->{chr_name}, $ftr_chr_set->runlist );
    };

    MCE::Flow::init {
        chunk_size  => 1,
        max_workers => $parallel,
    };
    my %feature_of = mce_flow $worker, \@chrs;
    MCE::Flow::finish;

    $ftr_of = \%feature_of;

    DumpFile( "${ensembl_db}_${feature}.yml", $ftr_of );
}

#----------------------------#
# Soft mask
#----------------------------#
if ($dir_fa) {
    my @files = sort File::Find::Rule->file->name('*.fa')->in($dir_fa);

    my @chrs = map { basename $_ , ".fa" } @files;    # strip dir and suffix
    while (1) {
        my $lcss = lcss(@chrs);
        last unless $lcss;
        print "LCSS [$lcss]\n";
        my $rx = quotemeta $lcss;
        $chrs[$_] =~ s/$rx// for 0 .. $#chrs;
    }
    my $file_of = { zip( @chrs, @files ) };

    for my $ftr_chr ( keys %{$ftr_of} ) { }

    my $worker = sub {
        my ( $self, $chunk_ref, $chunk_id ) = @_;
        my $ftr_chr = $chunk_ref->[0];

        my $ftr_chr_cmp = $ftr_chr;
        if ( $ftr_chr_cmp =~ /^chr/ ) {
            $ftr_chr_cmp =~ s/chr//;
        }

        # use the most similar file name
        my ($file_chr) = map { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map { [ $_, compare( $_, $ftr_chr_cmp ) ] } keys %{$file_of};

        printf "Write masked seq for ftr_chr [%s]\tfile_chr [%s]\n", $ftr_chr, $file_chr;

        # feature set
        my $ftr_set = AlignDB::IntSpan->new( $ftr_of->{$ftr_chr} );

        # seq
        my ( $seq_of, $seq_names ) = read_fasta( $file_of->{$file_chr} );
        my $seq = $seq_of->{ $seq_names->[0] };

        my @sets = $ftr_set->sets;
        for my $set (@sets) {
            my $offset = $set->min - 1;
            my $length = $set->size;

            my $str = substr $seq, $offset, $length;
            $str = lc $str;
            substr $seq, $offset, $length, $str;
        }

        open my $out_fh, '>', $file_of->{$file_chr} . ".masked";
        print {$out_fh} ">chr$ftr_chr\n";
        print {$out_fh} substr( $seq, 0, $linelen, '' ) . "\n" while ($seq);
        close $out_fh;

        MCE->gather( $file_of->{$file_chr} );
    };

    MCE::Flow::init {
        chunk_size  => 1,
        max_workers => $parallel,
    };
    my @matched_files = mce_flow $worker, [ sort keys %{$ftr_of} ];
    MCE::Flow::finish;

    {    # combine all unmatched filess to chrUn.fasta
        my $fa_set = Set::Scalar->new;
        $fa_set->insert($_) for @files;
        $fa_set->delete($_) for @matched_files;

        print "\n";
        printf "There are %d unmatched file(s)\n", $fa_set->size;
        if ( $fa_set->size ) {
            my $str = join " ", map { basename $_} $fa_set->elements;
            print "We'll combine these files into chrUn.fasta\n";
            print $str, "\n";

            system "cat $str > chrUn.fasta";
            system "rm $str";
        }
    }
}

$stopwatch->end_message;

# comes from
# http://stackoverflow.com/questions/499967/how-do-i-determine-the-longest-similar-portion-of-several-strings
sub lcss {
    return '' unless @_;
    return $_[0] if @_ == 1;
    my $i          = 0;
    my $first      = shift;
    my $min_length = length($first);
    for (@_) {
        $min_length = length($_) if length($_) < $min_length;
    }
INDEX: for my $ch ( split //, $first ) {
        last INDEX unless $i < $min_length;
        for my $string (@_) {
            last INDEX if substr( $string, $i, 1 ) ne $ch;
        }
    }
    continue { $i++ }
    return substr $first, 0, $i;
}

__END__

