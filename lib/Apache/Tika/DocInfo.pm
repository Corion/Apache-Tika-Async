package Apache::Tika::DocInfo;
use Moo;
use vars qw($VERSION);
$VERSION = '0.06';

has meta => (
    is => 'ro',
);

has content => (
    is => 'ro',
);

1;