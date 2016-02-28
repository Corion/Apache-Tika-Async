#!perl -w
use strict;
use Apache::Tika::Server;

use Data::Dumper;
my $tika= Apache::Tika::Server->new(
    #java => '"C:/Program Files (x86)/Java/jre7/bin/java.exe"',
);
#my $tika= Apache::Tika->new;
$tika->launch();

my $fn= shift;

#print Dumper $tika->get_meta($fn);

print Dumper $tika->get_text($fn)->content;
