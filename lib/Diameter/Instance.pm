package Diameter::Instance;

use strict;
use warnings;

use IO::Socket::INET;
use IO::Pipe;
use IO::Select;
use Log::Log4perl qw(:easy);
use Data::Dumper;

use POSIX ":sys_wait_h";

Log::Log4perl->easy_init( $DEBUG );


#
# $instance = Diameter::Instance->new( OriginHost => $oh, OriginRealm => $or, OnIncomingMessage => \&sub );
# $peer = $instance->connect_to_peer( PeerAddr => $addr, PeerPort => $port, WaitForStatus => 0|1,  OnSuccess => \&sub, OnFailure => \&sub, OnPeerClosure => \&sub );
# $instance->start_listening( BindAddr => $addr, BindPort => $port, OnSuccess => \&sub, OnFailure => \&sub, OnNewIncomingPeer => \&sub, OnPeerClosure => \&sub );
# $instance->send_message_to_peer( $peer, $message, OnFailure => \&sub );
#
# $peer->origin_host;
# $peer->origin_realm;
# $peer->address;
# $peer->port;
# $peer->state;
#
# $notice = $instance->notice_ready();
# $notice = $instance->wait_for_notice();
#
# $notice->{type}     # "incoming_message"|"message_delivery_failure"|"message_delivery_success"|"peer_closed"|"fatal"
# $notice->{message}  # for "incoming_message", "message_delivery_failure", "message_deliver_success"
# $notice->{peer}     # for "incoming_message", "peer_closed" and sometimes, "fatal"
# $notice->{error}    # for "message_delivery_failure" and "fatal"
# 


use constant {
    ORIGIN_HOST       => 0,
    ORIGIN_REALM      => 1,
    WATCHDOG_INTERVAL => 2,
    MSG_QUEUE         => 3,
    PEER_LIST         => 4,
    AM_HANDLER        => 5,
    READ_FRAGMENT     => 6,
};

sub new {
    my $class = shift;
    my %params = @_;

    DEBUG "[$class\:\:new]";

    unless (exists $params{OriginHost} && defined $params{OriginHost} && $params{OriginHost} ne "") {
        $@ = "Must provide OriginHost";
        return undef;
    }

    unless (exists $params{OriginRealm} && defined $params{OriginRealm} && $params{OriginRealm} ne "") {
        $@ = "Must provide OriginRealm";
        return undef;
    }

    my $self = bless [
        $params{OriginHost},
        $params{OriginRealm},
        60,
        Diameter::Instance::MessageQueue->new,
        Diameter::Instance::MessageQueue->new,
        [],
        0,
        '',
    ], $class;

    DEBUG " forking";

    my $r = fork();

    if (!defined $r) {
        $@ = "Fork failed ($?)";
        return undef;
    }

    if ($r == 0) {
        $0 = "Diameter::Instance::Handler $params{OriginHost}";

        DEBUG "  (handler) thread";

        $self->[SYNC_MSG_QUEUE]->am_left_endpoint;
        $self->[ASYNC_MSG_QUEUE]->am_left_endpoint;
        $self->[AM_HANDLER] = 1;

        $self->_start_network_loop();

        my $kid;
        do {
            $kid = waitpid(-1, WNOHANG);
        } while ($kid > 0);

        exit;
    }
    else {
        DEBUG "  (parent) thread";

        $self->[SYNC_MSG_QUEUE]->am_right_endpoint;
        $self->[ASYNC_MSG_QUEUE]->am_right_endpoint;
        return $self;
    }
}


#sub _read_msgs_from_pipe {
#    my $self = shift;
#
#    my $me = ($self->[AM_HANDLER] ? "handler" : "parent");
#
#    DEBUG " ($me) [_read_msgs_from_pipe]";
#
#    my $incoming;
#    $self->[READ_PIPE]->sysread( $incoming, 4096 )
#        or die "Failed to read pipe for message ($!)\n";
#
#    $incoming = $self->[READ_FRAGMENT] . $incoming;
#
#    my @msgs;
#    while ($incoming) {
#        if (length( $incoming ) >= 4) {
#            DEBUG "  ($me) incoming >= 4";
#
#            my $next_msg_len = unpack( "L", substr( $incoming, 0, 4 ) );
#
#            DEBUG "    ($me) next_msg_len = $next_msg_len";
#
#            if (length( $incoming ) >= $next_msg_len + 4) {
#                DEBUG "      ($me) have complete message";
#
#                substr $incoming, 0, 4, '';
#                my $blob = substr $incoming, 0, $next_msg_len, '';
#
#                my $msg = thaw( $blob );
#
#                # DEBUG "        ($me) msg = " . Dumper( $msg );
#
#                push @msgs, $msg;
#            }
#            else {
#                DEBUG "      ($me) do not have complete message";
#
#                $self->[READ_FRAGMENT] = $incoming;
#                last;
#            }
#        }
#        else {
#            DEBUG " ($me) incoming < 4";
#
#            $self->[READ_FRAGMENT] = $incoming;
#            last;
#        }
#    }
#
#    return @msgs;
#}
#
#
#sub _write_msg_to_pipe {
#    my $self = shift;
#
#    my $me = ($self->[AM_HANDLER] ? "handler" : "parent");
#
#    DEBUG " ($me) [_write_msg_to_pipe]";
#
#    my $blob = freeze( $_[0] );
#    my $blob_len = pack( "L", length( $blob ) );
#
#    DEBUG "   ($me) blob_len = " . length( $blob );
#
#    $self->[WRITE_PIPE]->syswrite( $blob_len . $blob )
#        or die "Failed to write pipe with message ($!)\n";
#}


sub _start_network_loop {
    my $self = shift;

    DEBUG " (handler) [_start_network_loop]";

    my $select = IO::Select->new()
        or die "Fatal: Failed to create IO::Select object ($!)\n";

    my $sync_queue_read_handle  = $self->[SYNC_MSG_QUEUE]->receive_pipe;
    my $async_queue_read_handle = $self->[ASYNC_MSG_QUEUE]->receive_pipe;

    $select->add( $sync_queue_read_handle )
        or die "Fatal: Failed to add read pipe in handler ($!)\n";

    $select->add( $async_queue_read_handle )
        or die "Fatal: Failed to add read pipe in handler ($!)\n";

    my $incoming;
    my $msg = '';

    while (1) {
        my @ready = $select->can_read;

        # DEBUG "  (handler) have ready read = " . scalar( @ready );

        foreach my $handle (@ready) {
            if ($handle eq $sync_queue_read_handle) {
                DEBUG "    (handler) next message is sync_queue_read";

                my $msg = $self->[SYNC_MSG_QUEUE]->receive_next_message;

                if ($msg->{notice} eq "ACCEPT_INCOMING") {
                    DEBUG "      (handler) message is ACCEPT_INCOMING: $msg->{BindAddr}, $msg->{BindPort}, $msg->{Timeout}\n";

                    my $is_successful = $self->_handler_start_listening( BindAddr => $msg->{BindAddr}, BindPort => $msg->{BindPort}, Timeout => $msg->{Timeout} );

                    if ($is_successful) {
                        DEBUG "        (handler) _handler_start_listening success, sending OK";
                        $self->[SYNC_MSG_QUEUE]->send_message( { notice => "OK" } );
                    }
                    else {
                        DEBUG "        (handler) _handler_start_listening success, sending FAILED";
                        $self->[SYNC_MSG_QUEUE]->send_message( { notice => "FAILED", error => $@ } );
                    }
                }
                elsif ($msg->{notice} eq "CONNECT_TO_PEER") {
                    DEBUG "      (handler) message is CONNECT_TO_PEER: $msg->{PeerAddr}, $msg->{PeerPort}, $msg->{Timeout}\n";

                    my $peer = $self->_handler_connect_to_peer( PeerAddr => $msg->{PeerAddr}, PeerPort => $msg->{PeerPort}, Timeout => $msg->{Timeout} );

                    if ($peer) {
                        $self->[SYNC_MSG_QUEUE]->send_message( { notice => "OK" } );
                    }
                    else {
                        $self->[SYNC_MSG_QUEUE]->send_message( { notice => "FAILED", error => $@ } );
                    }
                }
                elsif ($msg->{notice} eq "TERMINATE") {
                    DEBUG "      (handler) message is TERMINATE";

                    $select->remove( $sync_queue_read_handle );
                    $select->remove( $async_queue_read_handle );

                    DEBUG "        (handler) sending OK";
                    $self->[SYNC_MSG_QUEUE]->send_message( { notice => "OK" } );

                    DEBUG "          (handler) sent";
                    $self->[SYNC_MSG_QUEUE]->close;
                    $self->[ASYNC_MSG_QUEUE]->close;
                }
                else {
                    die "Received unknown message on sync_queue in handler.  notice = $msg->{notice}\n";
                }
            }
#            if ($handle eq $self->[READ_PIPE]) {
#                my @msgs = $self->_read_msgs_from_pipe();
#
#                DEBUG "    (handler) have " . scalar( @msgs ) . " messages waiting";
#
#                foreach my $msg (@msgs) {
#                    if ($msg->{notice} eq "CONNECT_TO_PEER") {
#                        DEBUG "      (handler) message is CONNECT_TO_PEER: $msg->{PeerAddr}, $msg->{PeerPort}, $msg->{Timeout}\n";
#
#                        my $peer = $self->_handler_connect_to_peer( PeerAddr => $msg->{PeerAddr}, PeerPort => $msg->{PeerPort}, Timeout => $msg->{Timeout} );
#
#                        if (!$peer) { DEBUG "    (handler) error on connect: $@" }
#                        else        { DEBUG "    (handler) connect successful" }
#                    }
#                    elsif ($msg->{notice} eq "ACCEPT_INCOMING") {
#                        DEBUG "      (handler) message is ACCEPT_INCOMING: $msg->{BindAddr}, $msg->{BindPort}, $msg->{Timeout}\n";
#
#                        my $is_successful = $self->_handler_start_listening( BindAddr => $msg->{BindAddr}, BindPort => $msg->{BindPort}, Timeout => $msg->{Timeout} );
#
#                        if ($is_successful) {
#                            $self->_write_msg_to_pipe( { notice => "OK" } );
#                        }
#                        else {
#                            $self->_write_msg_to_pipe( { notice => "FAILED", error => $@ } );
#                        }
#                    }
#                    elsif ($msg->{notice} eq "TERMINATE") {
#                        DEBUG "      (handler) message is TERMINATE";
#                        
#                        $self->_write_msg_to_pipe( { notice => "TERMINATED" } );
#                        $select->remove( $self->[READ_PIPE] );
#                        $self->[READ_PIPE]->close;
#                        $self->[WRITE_PIPE]->close;
#                        return;
#                    }
#                }
#            }
        }
    }
}


sub _handler_connect_to_peer {
    my ($self, %params) = @_;

    DEBUG "    (handler) [_handler_connect_to_peer]";

    my $peer_socket = IO::Socket::INET->new(
        PeerHost        => $params{PeerAddr},
        PeerPort        => $params{PeerPort},
        Timeout         => $params{Timeout},
        Proto           => 'tcp',
    );

    unless (defined $peer_socket) {
        DEBUG "      (handler) connect failed";

        $@ = "Failed to connect to peer ($!)";
        return undef;
    }

    DEBUG "      (handler) connect succeeded";

    return Diameter::Instance::Peer->new( $peer_socket, "TRANSPORT_CONNECTED" );
}


sub _handler_start_listening {
    my $self = shift;
    my %params = @_;
    
    #BindAddr => $msg->{BindAddr}, BindPort => $msg->{BindPort}, Timeout => $msg->{Timeout} );

    return 1;
}


sub connect_to_peer {
    my $self = shift;
    my %params = @_;

    unless (exists $params{PeerAddr} && defined $params{PeerAddr} && $params{PeerAddr} ne "") {
        $@ = "Must provide valid PeerAddr";
        return undef;
    }

    unless (exists $params{PeerPort} && defined $params{PeerPort} && $params{PeerPort} =~ /^\d+$/ && $params{PeerPort} > 0 && $params{PeerPort} < 65536) {
        $@ = "Must provide valid PeerPort";
        return undef;
    }

    if (!exists $params{Timeout} || !defined $params{Timeout} || $params{Timeout} !~ /^\d+$/) {
        $params{Timeout} = 60;
    }

    $self->[SYNC_MSG_QUEUE]->send_message( { notice => "CONNECT_TO_PEER", PeerAddr => $params{PeerAddr}, PeerPort => $params{PeerPort}, Timeout => $params{Timeout} } )
        or die "Failed to write to handler pipe ($!)\n";

    my $response = $self->[SYNC_MSG_QUEUE]->receive_next_message();

    if ($response->{notice} eq "FAILED") {
        $@ = $response->{error};
        return undef;
    }

    return 1;
}


sub terminate {
    my $self = shift;

    $self->[SYNC_MSG_QUEUE]->send_message( { notice => "TERMINATE" } );

    my $incoming = $self->[SYNC_MSG_QUEUE]->receive_next_message();

    $self->[SYNC_MSG_QUEUE]->close;
    $self->[ASYNC_MSG_QUEUE]->close;
}


sub accept_incoming_connections {
    my $self = shift;
    my %params = @_;

    unless (exists $params{BindAddr} && defined $params{BindAddr} && $params{BindAddr} ne "") {
        $@ = "Must provide valid BindAddr";
        return undef;
    }

    unless (exists $params{BindPort} && defined $params{BindPort} && $params{BindPort} =~ /^\d+$/ && $params{BindPort} > 0 && $params{BindPort} < 65536) {
        $@ = "Must provide valid BindPort";
        return undef;
    }

    if (!exists $params{Timeout} || !defined $params{Timeout} || $params{Timeout} !~ /^\d+$/) {
        $params{Timeout} = 60;
    }

    $self->[SYNC_MSG_QUEUE]->send_message( { notice => "ACCEPT_INCOMING", BindAddr => $params{BindAddr}, BindPort => $params{BindPort}, Timeout => $params{Timeout} } )
        or die "Failed to write to handler pipe ($!)\n";

    my $response = $self->[SYNC_MSG_QUEUE]->receive_next_message();

    if ($response->{notice} eq "FAILED") {
        $@ = $response->{error};
        return undef;
    }

    return 1;

}


sub notice_ready {
}


sub wait_for_notice {
}


sub send_message_to_peer {
}


package Diameter::Instance::MessageQueue;

use strict;
use warnings;

use IO::Pipe;
use IO::Select;
use Storable qw[freeze thaw];
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init( $DEBUG );

# $eq = Diameter::Instance::MessageQueue->new;
# 
# fork()
# $eq->am_left_endpoint   (in parent)
# $eq->am_right_endpoint  (in child)
#
# $eq->send_message( $msg );
#
# $eq->wait_for_messages();
# if ($eq->messages_are_waiting) { ... }
#
# while (my $msg = $eq->receive_next_message) { ... }
# 

sub new {
    my $class = shift;

    DEBUG " [$class\:\:new]";

    return bless {
        pipe1       => IO::Pipe->new,
        pipe2       => IO::Pipe->new,
        rcv_queue   => [],
        read_fragment => '',
        name        => "",
    }, $class;
}


sub am_left_endpoint {
    my $self = shift;

    DEBUG "   [am_left_endpoint]";

    $self->{receive_pipe} = $self->{pipe1}->reader;
    $self->{send_pipe}    = $self->{pipe2}->writer;
    $self->{select}       = IO::Select->new( $self->{receive_pipe} );
    $self->{name}         = "left_endpoint";

    delete $self->{pipe1};
    delete $self->{pipe2};
}

sub am_right_endpoint {
    my $self = shift;

    DEBUG "   [am_right_endpoint]";

    $self->{receive_pipe} = $self->{pipe2}->reader;
    $self->{send_pipe}    = $self->{pipe1}->writer;
    $self->{select}       = IO::Select->new( $self->{receive_pipe} );
    $self->{name}         = "right_endpoint";

    delete $self->{pipe1};
    delete $self->{pipe2};
}


sub set_name {
    shift->{name} = shift;
}


sub send_message {
    my $self = shift;

    my $blob = freeze( $_[0] );
    my $blob_len = pack( "L", length( $blob ) );

    DEBUG "     ($self->{name}) send_message length (" . length( $blob ) . ")";

    $self->{send_pipe}->syswrite( $blob_len . $blob )
        or die "Failed to write pipe with message ($!)\n";
}


sub send_pipe {
    return shift->{send_pipe};
}


sub receive_pipe {
    return shift->{receive_pipe};
}


sub receive_next_message {
    my $self = shift;

    DEBUG "      ($self->{name}) [receive_next_message]";

    if (@{ $self->{rcv_queue} } > 0) {
        DEBUG "        -- ($self->{name}) message waiting on receive_queue";

        my $next_msg = shift @{ $self->{rcv_queue} };
        return $next_msg;
    }

    while (@{ $self->{rcv_queue} } == 0) {
        my $incoming;
        $self->{receive_pipe}->sysread( $incoming, 8192 )
            or die "Failed to read pipe for message ($!)\n";

        DEBUG "        -- ($self->{name}) Read " . length( $incoming ) . " bytes";

        $incoming = $self->{read_fragment} . $incoming;

        my @msgs;

        INCOMING_CHUNK:
        while ($incoming) {
            if (length( $incoming ) >= 4) {
                my $next_msg_len = unpack( "L", substr( $incoming, 0, 4 ) );

                DEBUG "          -- ($self->{name}) next_msg_len = $next_msg_len";

                if (length( $incoming ) >= $next_msg_len + 4) {
                    DEBUG "          -- ($self->{name}) extracting message";

                    substr $incoming, 0, 4, ''; # remove length indicator

                    my $blob = substr $incoming, 0, $next_msg_len, '';
                    my $msg = thaw( $blob );

                    push @{ $self->{rcv_queue} }, $msg;
                }
                else {
                    $self->{read_fragment} = $incoming;
                    last INCOMING_CHUNK;
                }
            }
            else {
                $self->{read_fragment} = $incoming;
                last INCOMING_CHUNK;
            }
        }
    }

    DEBUG "        -- ($self->{name}) returning message";

    return shift @{ $self->{rcv_queue} };
}


sub close {
    my $self = shift;

    $self->{receive_pipe}->close;
    $self->{send_pipe}->close;
}


package Diameter::Instance::Peer;

use strict;
use warnings;

use constant {
    SOCKET      => 0,
    STATE       => 1,
};

# $p = Diameter::Instance::Peer->new( $socket, $state );
sub new {
    my $class = shift;
    my ($socket, $state) = @_;

    return bless [$socket, $state], $class;
}



1;
