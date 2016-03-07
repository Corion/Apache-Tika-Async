package Apache::Tika::Server;
use strict;
use Carp qw(croak);
# Fire up/stop a Tika instance
use Moo;
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request::Common;
use Apache::Tika::DocInfo;
use JSON::XS 'decode_json';
use Data::Dumper;
use Promises;

use Apache::Tika::Connection::AEHTTP;
#use Apache::Tika::Connection::LWP;

=head1 SYNOPSIS

    use Apache::Tika::Server;

    my $tika= Apache::Tika::Server->new();
    $tika->launch();

    my $fn= shift;

    use Data::Dumper;
    print Dumper $tika->get_meta($fn);
    print Dumper $tika->get_text($fn);

=cut

use vars '$VERSION';
$VERSION = '0.01';

# We should use AnyEvent::HTTP, to nicely integrate with other event loops
# Or Promises, to do that.

extends 'Apache::Tika';

has pid => (
    is => 'rw',
    #isa => 'Int',
);

has port => (
    is => 'ro',
    #isa => 'Int',
    default => sub { 9998 },
);

has fh => (
    is => 'rw',
    #isa => 'Array',
);

has connection_class => (
    is => 'ro',
    default => 'Apache::Tika::Connection::AEHTTP',
);

has ua => (
    is => 'rw',
    #isa => 'Str',
    default => sub { $_[0]->connection_class->new },
    #default => sub { Apache::Tika::Connection::LWP->new },
);

sub cmdline {
    my( $self )= @_;
    $self->java,
    @{$self->java_args},
    '-jar',
    $self->jarfile,
    #'--port', $self->port,
    @{$self->tika_args},
};

sub launch {
    my( $self )= @_;
    if( !$self->pid ) {
        my $cmdline= join " ", $self->cmdline; # well, for Windows...
        #warn $cmdline;
        my $pid= open my $fh, "$cmdline |"
            or croak "Couldn't launch [$cmdline]: $!/$^E";
        $self->pid( $pid );
        $self->fh( $fh );
        sleep 2; # Java...
    };
}

sub url {
    # XXX Should return URI instead
    my( $self, $type )= @_;
    $type||= 'text';
    
    my $url= {
        text => 'rmeta',
        test => 'tika', # but GET instead of PUT
        meta => 'rmeta',
        #all => 'all',
        all => 'rmeta',
        # unpack
    }->{ $type };
    
    sprintf
        'http://127.0.0.1:%s/%s',
        $self->port,
        $url
};


sub synchronous($) {
    my $promise = $_[0];
    my @res;
    if( $promise->is_unfulfilled ) {
        my $await = AnyEvent->condvar;
        $promise->then(sub{ $await->send(@_)});
        @res = $await->recv;
    } else {
        #use Data::Dumper;
        #warn Dumper $promise->result;
        @res = @{ $promise->result }
    }
    @res
};

# /rmeta
# /unpacker
# /all
# /tika
#    hello world
sub fetch {
    my( $self, %options )= @_;
    $options{ type }||= 'text';
    my $url= $self->url( $options{ type } );
    
    my $content= $options{ content };
    my $content_size;
    if(! $content and $options{ filename }) {
        # read $options{ filename }
        open my $fh, '<', $options{ filename }
            or croak "Couldn't read '$options{ filename }': $!";
        binmode $fh;
        local $/;
        $content = <$fh>;
        $content_size= length $content;
    };
    
    my $method;
    if( 'test' eq $options{ type } ) {
        $method= 'get';
    } else {
        $method= 'put';# , "Content-Length" => $content_size, #Content => $content
        ;
    };
    
    my ($code,$res) = synchronous
        $self->ua->request( $method, $url, $content );
    my $info;
    if( 'all' eq $options{ type } or 'text' eq $options{ type } ) {
        my $item = $res->[0];

        # Should/could this be lazy?
        my $c = delete $item->{'X-TIKA:content'};
        #warn Dumper $item;
        $info= Apache::Tika::DocInfo->new({
            content => $c,
            meta => $item,
        });
    } else {
        # Must be '/meta'
        #warn $res->as_string;
        $info= Apache::Tika::DocInfo->new(
            rmeta => $res,
            content => undef,
        );
    };
    $info
}

sub DEMOLISH {
    kill -9 => $_[0]->pid
        if( $_[0] and $_[0]->pid );
}

__PACKAGE__->meta->make_immutable;

1;