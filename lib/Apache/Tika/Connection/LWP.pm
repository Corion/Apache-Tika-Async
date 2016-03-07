package Apache::Tika::Connection::LWP;
use LWP::UserAgent;
use LWP::ConnCache;
use Promises qw(deferred);
use Try::Tiny;
use Moo;
with 'Apache::Tika::Connection';

has ua => (
    is => 'ro',
    #isa => 'Str',
    default => sub { my $ua= LWP::UserAgent->new(); $ua->conn_cache( LWP::ConnCache->new ); $ua },
);

sub request {
    my( $self, $method, $url, $content, @content ) = @_;
    # Should initialize
    
    my $content_size = length $content;
    
    my @content= $content
               ? ('Content' => $content,
                  "Content-Length" => $content_size,
                  )
               : ();
    warn "[[$url]]";
    my $res = $self->ua->$method( $url, @content);
    
    print $res->as_string;
    
    my $p = deferred;
    my ( $code, $response ) = $self->process_response(
        $res->request,                      # request
        $res->code,    # code
        $res->message,    # msg
        $res->decoded_content,                        # body
        $res->headers                      # headers
    );
    $p->resolve( $code, $response );
    
    $p->promise
}

1;