package Apache::Tika::DocInfo;
use Moo;
our $VERSION = '0.10';

has meta => (
    is => 'ro',
);

has content => (
    is => 'ro',
);

1;