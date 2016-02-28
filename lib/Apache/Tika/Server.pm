package Apache::Tika::Server;
use strict;
use Carp qw(croak);
# Fire up/stop a Tika instance
use Moo;
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request::Common;
#use Archive::Zip;
#use IO::String;
use Apache::Tika::DocInfo;
use JSON::XS 'decode_json';
use Data::Dumper;

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

has '+jarfile' => (
    is => 'rw',
    #isa => 'Str',
    #default => 'jar/tika-server-1.5-20130816.014724-18.jar',
    default => sub {
        # Do a natural sort on the dot-version
        (sort { my $ad; $a =~ /server-1.(\d+)/ and $ad=$1;
                my $bd; $b =~ /server-1.(\d+)/ and $bd=$1;
                $bd <=> $ad
              } glob 'jar/tika-server-*.jar')[0]
    },
);

has ua => (
    is => 'rw',
    #isa => 'Str',
    default => sub { my $ua= LWP::UserAgent->new(); $ua->conn_cache( LWP::ConnCache->new ); $ua },
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
        # Unfortunately, Tika returns the metadata as invalid HTTP headers
        # which HTTP::Header does not like. So we fetch all information
        # as the zip archive:
        #text => 'all',
        text => 'rmeta',
        test => 'tika', # but GET instead of PUT
        meta => 'rmeta',
        #all => 'all',
        all => 'rmeta',
        # unpack
    }->{ $type };
    
    sprintf
        'http://localhost:%s/%s',
        $self->port,
        $url
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
    my @content= $content
               ? ('Content' => $content, "Content-Length" => $content_size, "Content-Type" => 'application/pdf', )
               : ();
    
    my $res=
        $self->ua->$method( $url, @content);
    my $info;
    if( 'all' eq $options{ type } or 'text' eq $options{ type } ) {
        my $payload = decode_json( $res->content );
        #use Data::Dumper;
        #warn Dumper $payload->[0];
        my $item = $payload->[0];

        # Should/could this be lazy?
        my $c = delete $item->{'X-TIKA:content'};
        warn Dumper $item;
        $info= Apache::Tika::DocInfo->new({
            content => $c,
            meta => $item,
        });
    } else {
        # Must be '/meta'
        #warn $res->as_string;
        $info= Apache::Tika::DocInfo->new(
            rmeta => +{ decode_json( $res->content ) },
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