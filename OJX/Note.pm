package OJX::Note;

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

1;
__END__
