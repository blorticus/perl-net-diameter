package Diameter::Types;

use strict;
use warnings;

use Regexp::Common qw[net];
use Moose::Util::TypeConstraints;

use MooseX::Types -declare => [
    qw(IPAddr L4Port DiameterIdentity Log4perlObject PeerState)
];

use MooseX::Types::Moose qw/Int Str Object/;

subtype IPAddr,
    as Str,
    where { /^$RE{net}{IPv4}$/ || $_ =~ /^$RE{net}{IPv6}$/ },
    message { "IP is not an IPv4 or an IPv6 address" };

subtype L4Port,
    as Int,
    where { $_ >= 0 && $_ < 65536 },
    message { "Port must be integer between 0 and 65535, inclusive" };

my $label = qr/[a-zA-Z0-9_]{1,63}|[a-zA-Z0-9_][a-zA-Z0-9_\-]{0,61}[a-zA-Z0-9_]/;
subtype DiameterIdentity,
    as Str,
    where {
        # Regexp::Common::net $RE{net}{domain} does not appear to match all currently
        # accepted domain characters
        (/^$label$/ || /^($label\.)+$label$/) && length($_) < 256 && !/^$RE{net}{IPv4}$/;
    },
    message { "Invalid DiameterIdentity" };

subtype Log4perlObject,
    as Object,
    where { defined $_ && UNIVERSAL::isa($_, 'Log::Log4perl::Logger') },
    message { "Logger must be a Log::Log5perl::Logger object" };

enum PeerState, [qw(DISCONNECTED TRANSPORT_CONNECTED DIAMETER_CONNECTED)];


1;
