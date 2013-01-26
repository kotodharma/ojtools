#!/usr/bin/perl -CLADS

use strict;
use 5.6.1;
use utf8;
use open qw(:std :utf8);
use OJX::Text qw(get_kanjiyomi);
use Getopt::Std;
use File::Spec::Functions;
use FindBin ();
use Carp;
# use Encode;
# binmode STDIN, ":utf8";
# binmode STDOUT, ":utf8";
sub logg;

our %opts;
getopts('hdn:k:', \%opts);
my $DEBUG = delete $opts{d};

if ($opts{h}) {
    unless (exec('perldoc', '-Tt', catfile($FindBin::Bin, $FindBin::Script))) {
        print STDERR "Usage: ojxgen.pl [options] inputfile [corpusfile(s)]\n";
        exit 1;
    }
    ## NOT REACHED - END OF PROGRAM
}

our %Config;
require 'ojxconf.pl';

my $max_jukugolen = $Config{jukugolen} || 4;  ## longest possible kanji compound

my $infile = shift;
croak "No input file specified" unless $infile;

if (@ARGV < 1) {
    croak 'No corpus files specified' if not $Config{files};
    my @globs = split /\s*,\s*/, $Config{files};
    push(@ARGV, glob) for (@globs);
}
my(%Dict, $corpusfile);

BUILD_DICTIONARY: {
    my $line = 0;
    while (<>) {
        if ($ARGV ne $corpusfile) {
            $corpusfile = $ARGV;
            logg "DEBUG: Reading corpusfile $ARGV" if $DEBUG;
            $line = 0;
        }
        chomp;
        $line++;

        next unless /^(\d+) T /;
        my @kanji;
        eval {
            @kanji = OJX::Text->get_kanjiyomi($_);
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
}

unless (scalar(keys %Dict)) {
    die "No corpora found";
}

READ_INPUT: {
    open(INFILE, $infile) or die "Cannot open input file $infile";
    my @lines;
    while (<INFILE>) {
        chomp;
        s/^\s*//;     # strip leading whitespace
        next if /^#/; # skip comments
        if (/^$/) {
            ## found blank line at the end of a chunk/poem
            process_chunk(@lines);
            @lines = ();
            next;
        } push(@lines, $_);
    }
    close INFILE;
    process_chunk(@lines) if @lines;
}

sub process_chunk {
    my @lines = @_;

    my $name;
    if ($lines[0] =~ /^N:(.*)$/) {
        ## Might need to accomodate other kinds of metadata in future.
        $name = $1;
        $name =~ s/^\s*//;  # strip leading whitespace
        $name ||= 'Unknown';
        printf "%s ===========================================================\n\n", $name,
        shift @lines;
    }
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
        my $prec = $opts{k} || 2;  ## precision (width) of line number fields
        printf "%.*d T $line %s\n%.*d M %s\n%.*d G \n\n",
            $prec, $ln, join(' ', @reads), $prec, $ln, compose(@reads), $prec, $ln;
        $ln++;
    }
    print "%\n" if $name;  ## only include footer for shorter, named texts
}

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

sub logg {
    my $msg = shift;
    print STDERR "$msg\n";
}

__END__

  Copyright 2012 David J. Iannucci

  This file is part of ojtools.

  ojtools is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  ojtools is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with ojtools.  If not, see <http://www.gnu.org/licenses/>.

=pod

=head1 NAME

ojxgen.pl - Read Old Japanese text and generate exegetical templates

=head1 SYNOPSIS

   ojxgen.pl [options] inputfile [corpusfile(s)]
   ojxgen.pl -h

   Options:
       -n<#> Start line numbering from number given
       -k<#> number of digits of padded width for line numbers (default = 2)
       -d    Give debugging output (where available)
       -h    Print this documentation (help)

=head1 DESCRIPTION

If corpus files are specified on the command line, only those specified are used;
if none are given, the ones listed in ojxconf.pl are used.

=head1 TODO

Document the input file format!

=head1 AUTHOR

David J. Iannucci <djiann@hawaii.edu>

=head1 VERSION

 0.43.2

=cut
