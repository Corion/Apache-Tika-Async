package Apache::Tika::Server;
use strict;
use Carp qw(croak);
# Fire up/stop a Tika instance
use Moo;

extends 'Apache::Tika';

has pid => (
    is => 'rw',
    #isa => 'Int',
);

has port => (
    is => 'ro',
    #isa => 'Int',
    default => sub { 8887 },
);

has fh => (
    is => 'rw',
    #isa => 'Array',
);

sub launch {
    my( $self )= @_;
    if( !$self->pid ) {
        my $cmdline= join " ", $self->cmdline; # well, for Windows...
        warn $cmdline;
        my $pid= open my $fh, "$cmdline |"
            or croak "Couldn't launch [$cmdline]: $!/$^E";
        warn "$pid/$fh";
        $self->pid( $pid );
        $self->fh( $fh );
    };
}

sub url {
    # XXX Should return URI instead
    my( $self )= @_;
    sprintf
        'http://localhost:%s/',
        $self->port
};

# /meta
# /unpacker
# /all
# /tiki
#    hello world
sub fetch {
...
}
sub DEMOLISH {
    kill -9 => $_[0]->pid
        if( $_[0] and $_[0]->pid );
}

__PACKAGE__->meta->make_immutable;

1;