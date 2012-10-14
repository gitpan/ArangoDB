package ArangoDB::Index;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use ArangoDB::Constants qw(:api);
use Class::Accessor::Lite ( ro => [qw/id collection_id type/] );

use overload
    q{""}    => sub { $_[0]->id },
    fallback => 1;

sub new {
    my ( $class, $conn, $params ) = @_;
    my $self = bless {%$params}, $class;
    $self->{connection} = $conn;
    weaken( $self->{connection} );
    $self->{collection_id} = ( split '/', $self->{id} )[0];
    return $self;
}

sub drop {
    my $self = shift;
    my $api  = API_INDEX . '/' . $self->{id};
    my $res  = eval { $self->{connection}->http_delete($api) };
    if ($@) {
        $self->_server_error_handler( $@, 'drop' );
    }
    return;
}

# Handling server error
sub _server_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the index(%s)', $action, $self->{id} );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__
