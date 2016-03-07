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

=head1 SYNOPSIS

    use Apache::Tika::Server;

    my $tika= Apache::Tika::Server->new();
    $tika->launch();

    my $fn= shift;

    use Data::Dumper;
    print Dumper $tika->get_meta($fn);
    print Dumper $tika->get_text($fn);
    print Dumper $tika->get_language($fn);

    my $info = $tika->get_all($fn);
    print Dumper $info->meta;

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
        language => 'language/string',
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
# /language
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
    # 'text/plain' for the language
    my @content= $content
               ? ('Accept' => 'application/json,text/plain', 'Content' => $content, "Content-Length" => $content_size, #"Content-Type" => 'application/pdf',
                 )
               : ();
    
    my $res=
        $self->ua->$method( $url, @content);
    my $info;
    if( 'all' eq $options{ type } or 'text' eq $options{ type } ) {
        if( $res->is_error ) {
            croak $res->as_string
        };
        my $payload = decode_json( $res->content );
        #use Data::Dumper;
        #warn Dumper $payload->[0];
        my $item = $payload->[0];
        
        # Should/could this be lazy?
        my $c = delete $item->{'X-TIKA:content'};
        # Ghetto-strip HTML we don't want:
        if( $c =~ m!<body>(.*)</body>!s ) {
            $c = $1;
            
            if( $item->{"Content-Type"} and $item->{"Content-Type"} =~ m!^text/plain\b!) {
                # Also strip the enclosing <p>..</p>
                warn "[[$c]]";
                $c =~ s!\A\s*<p>(.*)\s*</p>\s*\z!$1!s;
            };
        } else {
            warn "Couldn't find body in response";
        };
        
        $info= Apache::Tika::DocInfo->new({
            content => $c,
            meta => $item,
        });
        
        if( ! defined $info->{meta}->{"meta:language"} ) {
            # Yay. Two requests.
            my $lang_meta = $self->fetch(%options, type => 'language');
            $info->{meta}->{"meta:language"} = $lang_meta->meta->{"info"};
        };
        
    } else {
        # Must be '/meta' or '/language'
        my ($payload, $item);
        if( $res->content_type eq 'application/json' ) {
            $payload = decode_json( $res->content );
            $item = $payload->[0];
        } else {
            $item = { info => $res->content };
        };

        my $c = delete $item->{'X-TIKA:content'};
        $info= Apache::Tika::DocInfo->new({
            meta => $item,
            content => undef,
        });
    };
    $info
}

sub DEMOLISH {
    kill -9 => $_[0]->pid
        if( $_[0] and $_[0]->pid );
}

__PACKAGE__->meta->make_immutable;

1;