package Diameter::Instance::CallbackStrategy;

use Moose;
use Diameter::Types qw[IPAddr L4Port DiameterIdentity Log4perlObject];
use Socket qw[SOMAXCONN inet_ntoa];
use IO::Async::Loop;
use Diameter::StreamReader;
use Log::Log4perl qw[get_logger];

use namespace::autoclean;

=head1 NAME

Diameter::Instance::CallbackStrategy - a Diameter peer instance using callbacks for functional flow

=head1 SYNOPSIS

 %handlers = (
    OnPeerConnected => sub {
        my $peer = shift;
        ...
    },

    OnMessage = sub {
        my $peer = shift;
        my $msg  = $dictionary->expand_message( shift );

        if ($msg->name eq "Credit-Control-Request") {
            $peer->send( Diameter::Dictionary->message( "CCA", ... ) );
        }
        elsif (...) {
            $peer->disconnect( Reason => $reason );
        }
    },

    OnStart => sub {
        my $instance = shift;

        $peer = $i->connect_to_peer( RemoteHost => $ip, RemotePort => $port );
    },
 );

 $i = Diameter::Instance->new( BindAddr => $addr, BindPort => $port, OriginHost => $oh, OriginRealm => $or, Handlers => \%handlers );
 $i->start;

=head1 METHODS

Constructor parameters:

=over 4

=item BindAddr

=item BindPort

=item OriginHost

=item OriginRealm

=item AdditionalCapabilitesAvps

=back

Method are:

=over 4

=item B<connect_to_peer>

Synchronously connect to a remote peer.

Arguments are: B<RemoteHost>, B<RemotePort>

Return value is: I<$peer> object or undef on failure (sets I<$@> on failure).

=item B<start>

Start the event loop.

=item B<terminate>

End the event loop.

Arguments are: 

=back

=head1 HANDLERS

=over 4

=item OnIncomingMessage

Arguments are: I<$peer>, I<$msg>

=item OnPeerTransportConnected

Arguments are: I<$remote_ip>, I<$remote_port>

=item OnPeerConnected

Arguments are: I<$peer>, I<$capabilities_exchange_msg>

=item OnPeerDisconnected

Arguments are: I<$peer>, I<$disconnect_msg>

=item OnPeerTransportDisconnected

Arguments are: I<$peer>, I<$reason>

=item OnWatchdog

Arguments are: I<$peer>, I<$watchdog_msg>

=item OnSendFailure

Arguments are: I<$peer>, I<$failed_msg>, I<$reason>

=item OnReadFailure

Arguments are: I<$peer>, I<$reason>

=item OnListenFailure

Arguments are: I<$reason>

=item OnTransportConnectFailure

Arguments are: I<$peer_ip>, I<$peer_port>, I<$reason>

=item OnDiameterConnectFailure

Arguments are: I<$peer_ip>, I<$peer_port>, I<$peer_origin_host>, I<$peer_origin_realm>, I<$reason>

=back

=cut

# $i = Diameter::Instance->new( BindAddr => $addr, BindPort => $port, OriginHost => $oh, OriginRealm => $or, Handlers => \%handlers );

has 'bind_addr',
    isa         => IPAddr,
    is          => 'ro',
    default     => '127.0.0.1';

has 'bind_port',
    isa         => L4Port,
    is          => 'ro',
    default     => 3868;

has 'origin_host',
    isa         => DiameterIdentity,
    is          => 'ro',
    required    => 1;

has 'origin_host',
    isa         => DiameterIdentity,
    is          => 'ro',
    required    => 1;

has 'handlers',
    isa         => 'Hashref',
    is          => 'ro',
    default     => sub { {} };

has 'loop',
    is          => 'rw',
    init_arg    => undef,
    lazy        => 1,
    reader      => '_get_loop',
    writer      => '_set_loop';

has 'stream_reader',
    is          => 'rw',
    init_arg    => undef,
    lazy        => 1,
    reader      => '_get_stream_reader',
    writer      => '_set_stream_reader';

has 'logger',
    is          => 'rw',
    isa         => Log4perlObject,
    default     => sub { get_logger("Diameter::Instance") };



# These are callbacks based on message type and whether the message
# is a Request or Answer.  Each sub will be passed a reference to the
# peer object for the incoming transport, then the message, then the
# Instance object  It is expected to return
# a list of ($close_transport, $err_msg).  If $close_transport is
# set to true, then the transport should be closed and the $peer
# state should be set to 'DISCONNECTED' by the caller.  If $err_msg
# is defined, then a state error occurred, and $err_msg will be
# the appropriate state error.
my %peer_message_callback = (
    257     => {    # Capabilities-Exchange
        'Request' => sub {
            my ($peer, $msg, $instance) = @_;

            if ($peer->state ne 'TRANSPORT_CONNECTED') {
                return (1, "received unexpected CER from peer");
            }

            my @avps = $msg->avps_by_code( 264 );

            if (!@avps) {
                return (1, "peer CER lacks Origin-Host AVP");
            }
            elsif (@avps > 1) {
                return (1, "peer CER asserts multiple Origin-Host AVPs");
            }

            my $origin_host = $avps[0];

            @avps = $msg->avps_by_code( 296 );

            if (!@avps) {
                return (1, "peer CER lacks Origin-Realm AVP");
            }
            elsif (@avps > 1) {
                return (1, "peer CER asserts multiple Origin-Realm AVPs");
            }

            my $origin_realm = $avps[0];

            $peer->_set_origin_host( $origin_host );
            $peer->_set_origin_realm( $origin_realm );

            $peer->send_message( $instance->generate_cea );

            return (0, undef);
        },

        'Answer'  => sub {
            # since the remote end initiated transport, it must send CER
            return (1, "incoming peer sent CEA");
        },
    },

    280     => {    # Device-Watchdog
        'Request' => sub {
            my ($peer, $msg, $instance) = @_;

            unless ($peer->state eq 'DIAMETER_CONNECTED') {
                return (1, "unexpected message (DWR) from disconnected peer");
            }

            $peer->send_message( $instance->generate_dwa );
        },

        'Answer'  => sub {
            my ($peer, $msg, $instance) = @_;

            unless ($peer->state eq 'DIAMETER_CONNECTED') {
                return (1, "unexpected message (DWA) from disconnected peer");
            }

            if (!$peer->is_watchdog_outstanding) {
                return (1, "incoming peer sent unsolicited DWA");                
            }

            $peer->_set_watchdog_outstanding( 0 );

            return (0, undef);
        },
    },

    282     => {    # Disconnect-Peer
        'Request' => sub {
            my ($peer, $msg, $instance) = @_;

        },

        'Answer'  => sub {
            my ($peer, $msg, $instance) = @_;

        },
    },

);


sub _signal_message_received {
    my $self = shift;
}


sub start {
    my $instance = shift;

    my $logger = $instance->logger;

    $logger->debug( '[Diameter::Instance::CallbackStrategy::start]' );

    my $loop = IO::Async::Loop->new;
    my $stream_reader = Diameter::StreamReader->new();

    $instance->_set_loop( $loop );
    $instance->_set_stream_reader( $stream_reader );

    $loop->listen(
        queuesize => SOMAXCONN,

        addr => {
            family      => 'inet',
            socktype    => 'stream',
            port        => $instance->bind_port,
            ip          => $instance->bind_addr,
        },

        on_fail => sub {
            my $entity = shift;

            $logger->debug( 'Start on_fail handler in listen loop' );

            if (($entity eq 'socket' || $entity eq 'listen') && exists $instance->handlers->{OnListenFailure}) {
                $instance->handlers->{OnListenFailure}->( $_[2] );
            }
            elsif ($entity eq 'bind' && exists $instance->handlers->{OnTransportConnectFailure}) {
                my ($port, $iaddr) = sockaddr_in( $_[0] );
                my $remote_ip = inet_ntoa( $iaddr );

                $instance->handlers->{OnTransportConnectFailure}->( $remote_ip, $port, $_[2] );
            }
        },

        on_stream => sub {
            my $stream = shift;
            my $socket = $stream->read_handle;

            $logger->debug( 'Start on_stream handler in listen loop' );

            if (exists $instance->handlers->{OnPeerTransportConnect}) {
                $instance->handlers->{OnPeerTransportConnect}->( $socket->peerhost, $socket->peerport );
            }

            my $peer = Diameter::Instance::Peer->new( local_bind_addr => $socket->sockhost, local_bind_port => $socket->sockport,
                                                      remote_addr     => $socket->peerhost, remote_port     => $socket->sockport,
                                                      state           => 'TRANSPORT_CONNECTED' );

            $stream->configure(
                on_read => sub {
                    my ($self, $buffref, $eof) = @_;

                    $logger->debug( 'Start on_read handler in on_stream' );

                    my @messages = $stream_reader->read( $$buffref );
                    $$buffref = '';

                    if ($stream_reader->read_failed) {
                        if (exists $instance->handlers->{OnReadFailure}) {
                            $instance->handlers->{OnReadFailure}->( $peer, $stream_reader->error() );
                        }

                        $peer->state('DISCONNECTED');
                        $stream->close_now();
                    }

                    foreach my $m (@messages) {
                        $instance->_signal_message_received;
                    }

                    if ($eof && exists $instance->handlers->{OnPeerTransportDisconnected}) {
                        $instance->handlers->{OnPeerTransportDisconnected}->( $peer, 'peer closed transport' );
                        $instance->state('DISCONNECTED');
                        $stream->close_now();
                    }
                },

                on_read_error => sub {
                    my $err = shift;

                    $logger->debug( "Start on_read_error handler in on_stream" );
                    $logger->warn( "read_error: $err" );

                    if (exists $instance->handlers->{OnReadError}) {
                        $instance->handlers->{OnReadError}->( $peer, $err );
                    }
                },

                on_write_error => sub {
                    my $err = shift;

                    $logger->debug( 'Start on_write handler in on_stream' );
                    $logger->warn( "write_error: $err" );

                    if (exists $instance->handlers->{OnSendError}) {
                        $instance->handlers->{OnSendError}->( $peer, $err );
                    }
                },
            );
    
            $loop->add( $stream );
        },
    )->get;

}

__PACKAGE__->meta->make_immutable;


1;
