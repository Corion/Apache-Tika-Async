package Apache::Tika::DocInfo;
use Moo;
our $VERSION = '0.07';

has meta => (
    is => 'ro',
);

has content => (
    is => 'ro',
);

1;