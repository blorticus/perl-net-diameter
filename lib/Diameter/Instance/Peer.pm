package Diameter::Instance::Peer;

use Moose;
use Diameter::Types qw[IPAddr L4Port DiameterIdentity PeerState];

use namespace::autoclean;


has 'local_bind_addr',
    is          => 'ro',
    isa         => IPAddr,
    default     => '127.0.0.1';

has 'local_bind_port',
    is          => 'ro',
    isa         => L4Port,
    default     => '3868';

has 'remote_addr',
    is          => 'ro',
    isa         => IPAddr,
    required    => 1;

has 'remote_port',
    is          => 'ro',
    isa         => L4Port,
    required    => 1;

has 'origin_host',
    is          => 'rw',
    isa         => DiameterIdentity,
    init_arg    => undef,
    writer      => '_set_origin_host';

has 'origin_realm',
    is          => 'rw',
    isa         => DiameterIdentity,
    init_arg    => undef,
    writer      => '_set_origin_realm';

has 'state',
    is          => 'rw',
    isa         => PeerState,
    default     => 'DISCONNECTED',
    writer      => '_set_state';

has 'is_watchdog_outstanding',
    is          => 'rw',
    isa         => Bool,
    default     => 0,
    writer      => '_set_watchdog_outstanding';


sub connect_to_peer {
    my $self = shift;
}


1;
