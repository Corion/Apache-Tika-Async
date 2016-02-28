#!perl -w
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
    MIN_PERL_VERSION => '5.012', # Well, that's what the source code says
    META_MERGE => {
        resources => {
            repository => "http://www.thenautilus.net/cgit/feeder",
        },
    },
    BUILD_REQUIRES => {
        'Exporter'   => '5',    # we need the "import" facility
        'Carp'       => '0',
    },
    'NAME' => 'feeder',
    'LICENSE' => 'agpl_3',
    'VERSION' => '1.0.0',
    'PREREQ_PM' => {
        'DBD::SQLite' => 0,        # For the duplicate database
        'DBI' => 0,                # For the duplicate database
        'DateTime' => 0,
        'Digest::SHA1' => 0,
        'Email::Address' => 0,
        'Encode' => 0,
        'Encode::IMAPUTF7' => 0,
        'HTML::ExtractMain' => 0,
        'LWP::UserAgent' => 6,
        'Log::Log4perl' => 0,
        'MIME::Lite' => 0,
        'Maildir::Lite' => 0,
        'Moose::Role' => 0,
        'MooseX::Traits' => 0,
        'MooseX::Types' => 0,
        'MooseX::Types::URI' => 0,
        'Sub::Exporter' => 0,
        'Template' => 0,
        'Template::Provider::Encoding' => 0,
        'Text::CleanFragment' => 0, # for transliteration
        'Try::Tiny' => 0,
        'URI' => 0,
        'XML::Feed' => 0,
        'namespace::autoclean' => 0,
    },
    ABSTRACT => 'Simple and extensible feed aggregator',
    AUTHOR => 'Gianni Ceccarelli <dakkar@thenautilus.net>',
);
