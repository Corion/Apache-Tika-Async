#!perl -w
use strict;
use Test2::V0;
use Apache::Tika::Server;
use Getopt::Long;
use File::Basename;
use File::Spec;

#GetOptions(
#    'jar|j=s' => \my $tika_path,
#);

use Data::Dumper;

my $tika_path;
if( ! $tika_path ) {
    my $tika_glob = File::Spec->rel2abs( dirname($0) ) . '/../jar/*.jar';
    note $tika_glob;
    $tika_path = Apache::Tika::Async->best_jar_file(glob $tika_glob);
    note $tika_path;
    die "Tika not found in '$tika_glob'" unless $tika_path and -f $tika_path;
}

my $tika= Apache::Tika::Server->new(
    jarfile => $tika_path,
    #connection_class => 'Apache::Tika::Connection::LWP',
    #connection_class => 'Apache::Tika::Connection::AEHTTP',
    #java => '"C:/Program Files (x86)/Java/jre7/bin/java.exe"',
);
$tika->launch();

for my $fn (@ARGV) {
    use Data::Dumper;
    my $zip = $tika->get_unpack($fn);

    for my $member ($zip->members) {
        note $member->fileName;
    }
}
#print Dumper $meta;

done_testing();
