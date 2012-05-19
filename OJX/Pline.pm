package OJX::Pline;

use strict;
use utf8;
use Carp;

########################################################################################
##
########################################################################################
sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    bless {}, $class;
}

########################################################################################
##
########################################################################################
sub match {
    my $self = shift;
    my($pat, $cmds) = @_;
    my $dat;

    if ($cmds->{T}) {
        $dat = $self->T;
        if ($pat =~ /[a-z]/i) {
            ### WHat was this for? -dji
        }
    }
    elsif ($cmds->{M}) {
        $dat = $cmds->{slash} ? $self->P : $self->M;
        $dat =~ s/^\d\d ?[MP]//; ## remove the line no and type code
        $dat =~ s/\[.*?\]//g;    ## remove contraction-elided segments
    }
    elsif ($cmds->{G}) {
        $dat = $self->G;
    }
    $dat =~ /$pat/i;
}

########################################################################################
##
########################################################################################
sub T {
    my $self = shift;
    if (my $val = shift) {
        $self->{T} = $val;
    }
    $self->{T};
}

########################################################################################
##
########################################################################################
sub M {
    my $self = shift;
    if (my $val = shift) {
        $self->{M} = $val;
        $val =~ s/\[.*?\]//g; ## remove contraction-elided segments
        $val =~ s/\s|[-.]//g; ## remove whitespace and boundary markers
        $self->{P} = $val;
    }
    $self->{M};
}

########################################################################################
##
########################################################################################
sub G {
    my $self = shift;
    if (my $val = shift) {
        $self->{G} = $val;
    }
    $self->{G};
}

########################################################################################
##
########################################################################################
sub P {
    my $self = shift;
    croak "P is a read-only property" if shift;
    $self->{P};
}

########################################################################################
##
########################################################################################
sub toString {
    my $self = shift;
    $self->{T} . "\n" .
    $self->{M} . "\n" .
    $self->{G};
}

1;
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

