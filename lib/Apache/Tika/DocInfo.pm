package Apache::Tika::DocInfo;
use Moo;

has meta => (
    is => 'ro',
    #isa => 'Hash',
);

has content => (
    is => 'ro',
    #isa => 'Int',
);

1;