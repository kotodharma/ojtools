#!/usr/bin/perl -CLADS

use strict;
use 5.6.1;
use utf8;
use open qw(:std :utf8);
use Module::Pluggable search_path => qw(OJX); eval "use $_" for plugins();
use Getopt::Std;
use File::Spec::Functions;
use FindBin ();
use Carp;
# use Encode;
# binmode STDIN, ":utf8";
# binmode STDOUT, ":utf8";
sub logg;

our %opts;
getopts('hdvnfTMGXNPEJ', \%opts);

if ($opts{h}) {
    unless (exec('perldoc', '-Tt', catfile($FindBin::Bin, $FindBin::Script))) {
        print STDERR "Usage: ojxfind.pl [options] CMD pattern [corpusfile(s)]\n";
        exit 1;
    }
    ## NOT REACHED - END OF PROGRAM
}
if ($opts{J}) {
    $opts{M} = $opts{N} = 1;
}
if ($opts{E}) {
    $opts{G} = $opts{X} = $opts{N} = 1;
}
if (($opts{G} || $opts{X}) && ($opts{v} || $opts{n})) {
    croak 'Insensitivity options make no sense with English search';
}
my $DEBUG = delete $opts{d};

our %Config;
require 'ojxconf.pl';

my $pattern = shift;
if ($pattern =~ s#^/##) {
    $opts{slash} = 1;
}

if (@ARGV < 1) {
    croak 'No corpus files specified' if not $Config{files};
    my @globs = split /\s*,\s*/, $Config{files};
    push(@ARGV, glob) for (@globs);
}
my($cfile, $line);

my $totfound;
our $divider;

while (my $tu = read_text_unit()) {
    my @found = $tu->match($pattern, \%opts);
    next if @found < 1;
    $totfound += @found;

    if ($opts{f} || $opts{P}) {
        print $tu->toString;
        next;
    }
    $divider = "--------\n";
    foreach my $item (@found) {
        my $disp;
        my $type = ref $item;
        eval {
            $disp = $type ? $item->toString : $item;
        };
        if ($@) {
            carp "Convert to string from type $type: $@";
            $disp = $item;
        }
        disp_out($tu->name, $disp);
    }
}
printf $divider . "Found %d matches.\n", $totfound;

## END OF MAIN CODE

sub read_text_unit {
    my($text, $elem);

    while (<>) {
        if ($ARGV ne $cfile) {
            if (ref $text) {
                logg "Text missing its end marker";
            }
            $cfile = $ARGV;
            print STDERR "DEBUG: Reading corpusfile $ARGV\n" if $DEBUG;
            $line = 0;
        }
        chomp;
        $line++;
    
        if (/^([^=]+) ={10,}\s*$/) {
            my $name = $1;
            if (ref $text) {
                logg "Text missing its end marker";
            }
            $text = new OJX::Text($name, $cfile);
            $text->raw($_);
            next;
        }
        next unless ref $text;  # ignore if we're not yet in a text
        $text->raw($_);
        next if /^\s*(#.*)?$/;  # ignore blank lines and comments

        if ($elem) {
            if (/^ /) {
                $elem .= $_;
                next;
            }
            $elem =~ s/\s+/ /gs;  # normalize whitepsace
            if ($elem =~ /^"/) {
                $text->xlat($elem);
            }
            elsif ($elem =~ s/^(\d\d?\.|[*])\s*//) {
                $text->notes($elem);
            }
            else {
                logg "Unexpected element type in text";
            }
            $elem = undef;
        }

        if (/^%/) {
            return $text;
        }
        elsif (/^(\d\d) (T|M|G) /) {
            $text->line($1, $2, $_);
        }
        elsif (/^("|\d\d?\.|[*])/) {
            $elem = $_;
        }
        else {
            logg "Unexpected stuff in the format ($_)";
        }
    }
}

sub disp_out {
    my($name, $cont) = @_;
    $cont =~ s/^/$name: /gm;
    print $divider . "$cont\n";
}

sub logg {
    my $msg = shift;
    print STDERR "$cfile, line $line: $msg\n";
}

## match M's across mulitple plines in a single line
## coloring of match text
## Make sure the wo's in kwo (girl) and wotoko (man) are distinguished where they need to be!
##   * also (related), don't match Nsa for sa (e.g.), unless -n is specified. Hard!
## do something different - powerful - with T-line searching
##   - pull out manyogana matching a given phonetic pattern
## rename slash fergodsake
## pull out allomorphs based on grammar gloss (i.e. put in CAUS, get -simey, etc)!!!
## OO getter semantics for object methods (line, xlat, notes)
## -l option : only print names of texts matching pattern
## match on text names?
## rationalize logging with use of Carp calls
## multiple commands, strung together, with conjunctive semantics? disjuctive ha?!?!?
__END__
=pod

=head1 NAME

ojxfind.pl - Extract patterns from Old Japanese exegeses

=head1 SYNOPSIS

   ojxfind.pl [options] CMD pattern [corpusfile(s)]
   ojxfind.pl -h

   CMD is one of -T, -M, -G, -X, -N, -P, -J, -E. Meaning is to search in:
       -T  T field of interlinear format
       -M  M field of interlinear format
       -G  G field of interlinear format
       -X  translation
       -N  notes
       -P  name field (think: "pull" texts matching a name; implies -f)
       -J  fields containing Japanese (M, N)
       -E  fields containing English (G, X, N)

   Options:
       -v  Kou/otu insensitive: treat vowels as though merged
       -n  Prenasality insensitive: neutralize medial obstruent voicing contrast
       -f  Output full texts, not just matching sections
       -d  Give extra debugging output (where available)
       -h  Print this documentation (help)

=head1 NOTES

Default behavior is to output only exegesis sections that match the pattern.

All patterns are treated as Perl regexes, unless (oddly enough) the pattern begins with /.
Patterns beginning with / are to be used with -M, -N, -J, and are searched in
morphosyntax-insensitive mode. This means that the given sequence of characters is found
while ignoring morphemic (including word) boundaries. Accordingly, patterns should contain
only alphabetic characters (including diacritics, etc).  Although this is intended for
finding romanized Japanese, sometimes English matches will turn up in the Notes.

If corpus files are specified on the command line, only those specified are used; if
none are given, the ones listed in ojxconf.pl are used as defaults. Files specified on
the commmand line are NOT combined with those listed in ojxconf.pl - it's either/or.

Contracted (elided) segments in forms like /t[ö] ip-u/ DV say-FIN, because they are not
included in the overt phonetics, are NOT matched in searching. I.e. you can find this
sequence with a pattern like "/tip", but not "/töip".

When using -v option, search pattern must be specified using ONLY neutral vowels i, e, o.

When using -n option, search pattern must be specified using ONLY voiceless consonants.

=head1 AUTHOR

David J. Iannucci <djiann@hawaii.edu>

=head1 VERSION

 0.43.1

=cut
