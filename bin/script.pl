#!perl -w
use strict;
use Apache::Tika::Server;

use Data::Dumper;

my $tika= Apache::Tika::Server->new(
    #java => '"C:/Program Files (x86)/Java/jre7/bin/java.exe"',
);
$tika->launch();
#my $tika= Apache::Tika->new;

my $fn= shift;

print "Content-Type: " . $tika->get_meta($fn)->{'Content-Type'} . "\n";

print $tika->get_text($fn)->content;
