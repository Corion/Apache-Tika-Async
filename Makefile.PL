#!perl -w
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
    MIN_PERL_VERSION => '5.012', # Well, that's what the source code says
    META_MERGE => {
        resources => {
            #repository => "http://www.thenautilus.net/cgit/feeder",
        },
    },
    BUILD_REQUIRES => {
        'Exporter'   => '5',    # we need the "import" facility
        'Carp'       => '0',
    },
    'NAME' => 'Apache::Tika',
    'LICENSE' => 'perl',
    'VERSION' => '0.1',
    'PREREQ_PM' => {
        'Carp' => 0,
        'Exporter' => 5,
        'Promises' => 0,
        'LWP::UserAgent' => 6,
        'Moo' => 0,
        'JSON::XS' => 0,
        'HTTP::Request::Common' => 0,
    },
);
