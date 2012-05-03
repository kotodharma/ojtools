package OJX::Text;

use strict;
use 5.6.1;
use utf8;
use Carp;


########################################################################################
##
########################################################################################
sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my($name, $file) = @_;
    bless { name => $name, file => $file }, $class;
}

########################################################################################
##
########################################################################################
sub name {
    my $self = shift;
    croak "name is a read-only property" if shift;
    $self->{name};
}

########################################################################################
##
########################################################################################
sub file {
    my $self = shift;
    croak "file is a read-only property" if shift;
    $self->{file};
}

########################################################################################
##
########################################################################################
sub raw {
    my $self = shift;
    my $raw = $self->{raw} ||= [];
    if (defined(my $arg = shift)) {
        push(@{ $raw }, $arg);
    }
    else {
        return @{ $raw };
    }
}

########################################################################################
##
########################################################################################
sub line {
    my $self = shift;
    my($ln, $lt, $cont) = @_;
    $ln = int($ln);
    my $line = $self->{$ln} ||= [ OJ::Pline->new ];
    my $pline = $line->[-1];
    if ($pline->$lt) {
        push(@{ $line }, $pline = OJ::Pline->new);
    }
    $pline->$lt($cont);
}

########################################################################################
##
########################################################################################
sub xlat {
    my $self = shift;
    my $xlat = $self->{xlat} ||= [];
    if (defined(my $arg = shift)) {
        push(@{ $xlat }, $arg);
    }
    else {
        return @{ $xlat };
    }
}

########################################################################################
##
########################################################################################
sub notes {
    my $self = shift;
    my $notes = $self->{notes} ||= [];
    if (defined(my $arg = shift)) {
        push(@{ $notes }, $arg);
    }
    else {
        return @{ $notes };
    }
}

########################################################################################
##
########################################################################################
sub toString {
    my $self = shift;
    join("\n", $self->raw) . "\n";
}

########################################################################################
##
########################################################################################
sub match {
    my $self = shift;
    my($pat, $cmds) = @_;
    my @found;

    if ($cmds->{P} && $self->name =~ /$pat/i) {
        return ($self->name);
    }

    ## Apply insensitivity transformations to pattern regex
    if ($cmds->{v}) {
        my $iv = $main::Config{ivowels};
        my $ev = $main::Config{evowels};
        my $ov = $main::Config{ovowels};
        $pat =~ s/i/$iv/gi;
        $pat =~ s/e/$ev/gi;
        $pat =~ s/o/$ov/gi;
    }
    if ($cmds->{n}) {
        my $x = '(?:\\s|[-])*' if $cmds->{slash};
        $pat =~ s/([kstp])/N?$x$1/gi;
    }

    if ($cmds->{T} || $cmds->{M} || $cmds->{G}) {
        for (my $n = 1; ; $n++) {
            my $la = $self->{$n} || last;
            foreach my $pline (@{ $la }) {
                if ($pline->match($pat, $cmds)) {
                    push(@found, $pline);
                }
            }
        }
    }
    if ($cmds->{X}) {
        push(@found, grep /$pat/i, @{ $self->{xlat} });
    }
    if ($cmds->{N}) {
        my @notes = $self->notes;
        if ($cmds->{slash}) {
  ### this doesn't do the right thing - FIX IT.
            ## s/[^a-z0-9]//ig for (@notes);
        }
        push(@found, grep /$pat/i, @notes);
    }

    return @found;
}

########################################################################################
##
########################################################################################
sub get_kanjiyomi {
    my $self = shift;
    my($line) = @_;
    my(undef, undef, $text, @reads) = split;
    my @kanji = split //, $text;
    unless (@kanji == @reads) {
        croak sprintf "Mismatch in number of kanji (%d) and readings (%d)\n",
            scalar(@kanji), scalar(@reads);
    }
    return map { $_, shift @reads } @kanji;
}

1;
__END__
