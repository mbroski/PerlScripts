use Data::Random qw/rand_chars/;
use strict;
my $len = 3;
my @char = ('$','&','@','-');
print   build('loweralpha') .build('numeric'). build('upperalpha') .build( \@char );
sub build {
  my ($set) = @_;
  rand_chars( set => $set, size => $len);
}