package Apache::Tika;
use strict;
use Moo;
use JSON::XS qw(decode_json);

has java => (
    is => 'rw',
    #isa => 'Str',
    default => 'java',
);

has jarfile => (
    is => 'rw',
    #isa => 'Str',
    default => 'jar/tika-app-1.4.jar',
);

has java_args => (
    is => 'rw',
    #isa => 'Array',
    builder => sub { [] },
);

has tika_args => (
    is => 'lazy',
    #isa => 'Array',
    builder => sub { [ ] },
);

sub cmdline {
    my( $self )= @_;
    $self->java,
    @{$self->java_args},
    '-jar',
    $self->jarfile,
    @{$self->tika_args},
};

sub fetch {
    my( $self, %options )= @_;
    my @cmd= $self->cmdline;
    push @cmd, $options{ type };
    push @cmd, $options{ filename };
    @cmd= map { qq{"$_"} } @cmd;
    #warn "[@cmd]";
    ''.`@cmd`
}

sub meta {
    my( $self, $file )= @_;
    return decode_json($self->fetch( filename => $file, type => '--json' ));
};
sub text {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => '--text' );
};
1;