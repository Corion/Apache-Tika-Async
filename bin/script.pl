#!perl -w
use strict;
use Apache::Tika;
#use LWP::UserAgent;

#my $tika= Apache::Tika::Server->new();
my $tika= Apache::Tika->new;
#$tika->launch();

my $fn= shift;

use Data::Dumper;
print Dumper $tika->meta($fn);
print Dumper $tika->text($fn);
