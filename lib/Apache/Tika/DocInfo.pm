package Apache::Tika::DocInfo;
use Moo;
use vars qw($VERSION);
$VERSION = '0.05';

has meta => (
    is => 'ro',
    #isa => 'Hash',
);

has content => (
    is => 'ro',
    #isa => 'Int',
);

1;