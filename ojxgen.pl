#!/usr/bin/perl -CLADS

use strict;
use 5.6.1;
use utf8;
use open qw(:std :utf8);
use OJText;# qw(OJ::Text::get_kanjiyomi);
use Getopt::Std;
use File::Spec::Functions;
use FindBin ();
use Carp;
# use Encode;
# binmode STDIN, ":utf8";
# binmode STDOUT, ":utf8";

our %opts;
getopts('hdn:', \%opts);

if ($opts{h}) {
    unless (exec('perldoc', '-Tt', catfile($FindBin::Bin, $FindBin::Script))) {
        print STDERR "Usage: ojxgen.pl [options] inputfile [corpusfile(s)]\n";
        exit 1;
    }
    ## NOT REACHED - END OF PROGRAM
}

our %Config;
require 'ojconf.pl';

my $max_jukugolen = $Config{jukugolen} || 4;  ## longest possible kanji compound

my $infile = shift;
if (@ARGV < 1) {
    croak 'No corpus files specified' if not $Config{files};
    my @globs = split /\s*,\s*/, $Config{files};
    push(@ARGV, glob) for (@globs);
}
my(%Dict, $corpusfile);

my $line = 0;
while (<>) {
    if ($ARGV ne $corpusfile) {
        $corpusfile = $ARGV;
        print STDERR "DEBUG: Reading corpusfile $ARGV\n" if $opts{d};
        $line = 0;
    }
    chomp;
    $line++;

    next unless /^(\d+) T /;
    my @kanji;
    eval {
        @kanji = OJ::Text->get_kanjiyomi($_);
    };
    if ($@) {
        carp "$corpusfile line $line: $@\n";
        next;
    }
    my @mknc;
    while(my($ji, $read) = splice(@kanji, 0, 2)) {
        if ($read eq '>>') {
            push(@mknc, $ji);
            if (@mknc >= $max_jukugolen) {
                croak sprintf "%s line %d: Jukugo of len > %d are not recognized\n",
                    $corpusfile, $line, $max_jukugolen;
            }
        }
        else {
            if (@mknc) {
                $ji = join('', (@mknc, $ji));
                @mknc = ();
            }
            $Dict{$ji}{$read}++;
        }
    }
}

unless (scalar(keys %Dict)) {
    die "No corpora found";
}

open(INFILE, $infile) or die "Cannot open input file $infile";

while (<INFILE>) {
    chomp;
    s/^\s*//; # strip leading whitespace
    next if /^$/ || /^#/; # skip empty lines and comments

    my $delim = qr/\/|\(\d+\)/o;
    my @lines = split /\s*$delim\s*/;
    my $name = ($lines[0] =~ /[a-z0-9]/i) ? shift(@lines) : 'NO_NAME';
    print "$name ===========================================================\n\n";

    my $ln = $opts{n} || 1;
    foreach my $line (@lines) {
        my @reads;
        my @kanji = split //, $line;
        while (@kanji) {
            my $ph = '??';
            my $test;
            for (my $i = ($max_jukugolen-1); $i >= 0; $i--) {
                $test = join('', @kanji[0..$i]);
                if (my $w = jibiku($test)) {
                    $ph = $w;
                    last;
                }
            }
## clean up usage of $test or something? what is its value in case of unknown kanji? etc etc
            my $len = length($test);
            push(@reads, ('>>') x ($len - 1), $ph);
            shift @kanji for (1..$len);
        }
        printf "%02d T $line %s\n%02d M %s\n%02d G \n\n",
            $ln, join(' ', @reads), $ln, compose(@reads), $ln;
        $ln++;
    }
    print "%\n";
}
close INFILE;

our $entry;

sub jibiku {
    my($ji) = @_;
    local $entry = $Dict{$ji};
    my($trans, $tunki) = sort readfreq keys %{$entry};
    # my $c1 = $entry->{$trans};
    # my $c2 = $entry->{$tunki};
    # return ($c2 > ($c1 / 2)) ? "$trans|$tunki" : $trans;
    return $trans;
}

sub compose {
    my @r = grep { $_ ne '>>' } @_;
    map { s/\|.*// } @r;
    join('', @r);
}

sub readfreq {
    my $ax = $a =~ /\?/ ? 0 : $entry->{$a};
    my $bx = $b =~ /\?/ ? 0 : $entry->{$b};
    $bx <=> $ax;
}

## Should we store ??s in Dict at all? (y - i think so) Should we point
##   out where they occur in the corpus if we have better data to replace
##   them with? (how?)

## Specialized behavior for when reading is something like two? with a ?
##    included (WTF does this mean? -dji)

## Meta-function: convert phonetic readings throughout all corpus files when
##   updating readings for a given man'yougana/semantogram.
__END__
=pod

=head1 NAME

ojxgen.pl - Read Old Japanese text and generate exegetical templates

=head1 SYNOPSIS

   ojxgen.pl [options] inputfile [corpusfile(s)]
   ojxgen.pl -h

   Options:
       -n<#> Start line numbering from number given
       -d    Give debugging output (where available)
       -h    Print this documentation (help)

=head1 DESCRIPTION

If corpus files are specified on the command line, only those specified are used;
if none are given, the ones listed in ojconf.pl are used.

=head1 AUTHOR

David J. Iannucci <djiann@hawaii.edu>

=head1 VERSION

 0.43.1

=cut
