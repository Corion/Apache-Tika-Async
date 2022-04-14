package Apache::Tika::Async;
use strict;
use Moo 2;
use JSON::XS qw(decode_json);

our $VERSION = '0.08';

=head1 NAME

Apache::Tika::Async - connect to Apache Tika

=head1 SYNOPSIS

    use Apache::Tika::Async;

    my $tika= Apache::Tika::Async->new;

    my $fn= shift;

    use Data::Dumper;
    my $info = $tika->get_all( $fn );
    print Dumper $info->meta($fn);
    print $info->content($fn);
    # <html><body>...
    print $info->meta->{"meta:language"};
    # en

=cut

has java => (
    is => 'rw',
    #isa => 'Str',
    default => 'java',
);

has 'jarfile' => (
    is => 'rw',
    #isa => 'Str',
# tika-server-1.24.1.jar
# tika-server-standard-2.3.0.jar

    default => sub {
        __PACKAGE__->best_jar_file(
              glob 'jar/tika-server-*.jar'
        );
    },
);

has java_args => (
    is => 'rw',
    #isa => 'Array',
    builder => sub { [
        # So that Tika can re-read some problematic PDF files better
        '-Dorg.apache.pdfbox.baseParser.pushBackSize=1000000'
    ] },
);

has tika_args => (
    is => 'rw',
    #isa => 'Array',
    default => sub { [ ] },
);

sub best_jar_file {
    my( $package, @files ) = @_;
    # Do a natural sort on the dot-version
    (sort { my $ad; $a =~ /\bserver-(?:standard-|)(\d+)\.(\d+)/ and $ad=sprintf '%02d.%04d', $1, $2;
            my $bd; $b =~ /\bserver-(?:standard-|)(\d+)\.(\d+)/ and $bd=sprintf '%02d.%04d', $1, $2;
                $bd <=> $ad
          } @files)[0]
}

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
    die "Fetching from local process is currently disabled";
    #warn "[@cmd]";
    ''.`@cmd`
}

sub decode_csv {
    my( $self, $line )= @_;
    $line =~ m!"([^"]+)"!g;
}

sub get_meta {
    my( $self, $file )= @_;
    #return decode_json($self->fetch( filename => $file, type => 'meta' ));
    # Hacky CSV-to-hash decode :-/
    return $self->fetch( filename => $file, type => 'meta' )->meta;
};

sub get_text {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'text' );
};

sub get_test {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'test' );
};

sub get_all {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'all' );
};

sub get_language {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'language' );
};

__PACKAGE__->meta->make_immutable;

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Apache-Tika-Async>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Apache-Tika-Async>
or via mail to L<apache-tika-async-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
