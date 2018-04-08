use Test::More;

BEGIN { use_ok 'Diameter::Types' };

use Diameter::Types qw[:all];

ok( !is_IPAddr(), "No parameter to IPAddr" );
ok( !is_IPAddr(''), "Empty String to IPAddr" );
ok( is_IPAddr( '203.0.113.1' ), "IPAddr 203.0.113.1" );
ok( is_IPAddr( '10.0.0.0' ), "IPAddr 10.0.0.0" );
ok( is_IPAddr( '255.0.0.0' ), "IPAddr 255.0.0.0" );
ok( is_IPAddr( '255.255.255.255' ), "IPAddr 255.255.255.255" );
ok( is_IPAddr( '0.0.0.0' ), "IPAddr 0.0.0.0" );
ok( !is_IPAddr( '203.0.113.256' ), "IPAddr 203.0.113.256" );

ok( is_IPAddr( '2001:abcd:0::1' ), 'IPAddr 2001:abc:0:1' );
ok( is_IPAddr( '2001:abcd:0123:1:21:123:0:1221' ), 'IPAddr 2001:abcd:0123:1:21:123:0:122');
ok( !is_IPAddr( '2001:abcd:0123:1:21:123:0:0:1221' ), 'IPAddr 2001:abcd:0123:1:21:123:0:0:122');
ok( !is_IPAddr( 'abcz:abcd:0123:1:21:123:0:1221' ), 'IPAddr abcz:abcd:0123:1:21:123:0:122');
ok( is_IPAddr( '::' ), 'IPAddr ::' );
ok( is_IPAddr( '::1' ), 'IPAddr ::1' );
ok( is_IPAddr( '1::' ), 'IPAddr 1::' );
ok( is_IPAddr( '1::1' ), 'IPAddr 1::1' );

ok( !is_IPAddr( 'foo' ), 'IPAddr foo' );
ok( !is_IPAddr( '10' ), 'IPAddr 10' );
ok( !is_IPAddr( 'abcd' ), 'IPAddr abcd' );
ok( !is_IPAddr( 'abcd:' ), 'IPAddr abcd:' );
ok( !is_IPAddr( ':abcd:' ), 'IPAddr :abcd:' );
ok( !is_IPAddr( '::abcd::' ), 'IPAddr ::abcd::' );
ok( !is_IPAddr( ':abcd::' ), 'IPAddr :abcd::' );
ok( !is_IPAddr( '::abcd:' ), 'IPAddr ::abcd:' );

ok( !is_L4Port(), "L4Port no parameter" );
ok( !is_L4Port(''), "L4Port empty string" );

my $invalid = -1;  # set this if a value fails, you can see which one
foreach my $i (0..65535) { unless (is_L4Port($i)) { $invalid = $i; last }  }

ok( $invalid == -1, 'All ports between 0..65535 valid L4Port' );

ok( !is_L4Port('-1' ), 'L4Port -1' );
ok( !is_L4Port('65536' ), 'L4Port 65536' );
ok( !is_L4Port('foo' ), 'L4Port foo' );
ok( !is_L4Port('ff' ), 'L4Port ff' );

ok( !is_DiameterIdentity(), 'DiameterIdentity no parameter' );
ok( !is_DiameterIdentity(''), 'DiameterIdentity empty string' );
ok( !is_DiameterIdentity(' '), 'DiameterIdentity space only' );
ok( is_DiameterIdentity('a'), 'DiameterIdentity a' );
ok( is_DiameterIdentity('a.foo.com'), 'DiameterIdentity a.foo.com' );
ok( is_DiameterIdentity('foo.com.a'), 'DiameterIdentity foo.com.a' );
ok( is_DiameterIdentity('FOO.COM.A'), 'DiameterIdentity FOO.COM.A' );
ok( is_DiameterIdentity('fOo.CoM.A'), 'DiameterIdentity foo.com.a' );
ok( is_DiameterIdentity('f00.com.a'), 'DiameterIdentity f00.com.a' );
ok( is_DiameterIdentity('_foo.com'), 'DiameterIdentity _foo.com' );
ok( !is_DiameterIdentity('-foo.com'), 'DiameterIdentity -foo.com' );
ok( !is_DiameterIdentity('foo.com-'), 'DiameterIdentity foo.com-' );
ok( !is_DiameterIdentity('-foo.com-'), 'DiameterIdentity -foo.com-' );
ok( is_DiameterIdentity('foo-1234.com'), 'DiameterIdentity foo-1234.com' );
ok( is_DiameterIdentity('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.foo.com' ), 'DiameterIdentity abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.foo.com (63 characters in first label)' );
ok( !is_DiameterIdentity('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.foo.com' ), 'DiameterIdentity abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.foo.com (64 characters: in first label)' );
ok( is_DiameterIdentity('foo.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghij.com' ), 'DiameterIdentity foo.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.com (63 characters: in second label)' );
ok( !is_DiameterIdentity('foo.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl.com' ), 'DiameterIdentity foo.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.com (64 characters: in second label)' );

ok( !is_PeerState(), 'PeerState no parameter' );
ok( !is_PeerState(undef), 'PeerState undef parameter' );
ok( !is_PeerState(''), 'PeerState emtpy string' );
ok( !is_PeerState('foo'), 'PeerState foo' );
ok( !is_PeerState(0), 'PeerState 0' );
ok( !is_PeerState(1), 'PeerState 1' );
ok( is_PeerState('DISCONNECTED'), 'PeerState DISCONNECTED' );
ok( is_PeerState('TRANSPORT_CONNECTED'), 'PeerState TRANSPORT_CONNECTED' );
ok( is_PeerState('DIAMETER_CONNECTED'), 'PeerState DIAMETER_CONNECTED' );
ok( !is_PeerState(' DIAMETER_CONNECTED'), 'PeerState DIAMETER_CONNECTED space before' );
ok( !is_PeerState('DIAMETER_CONNECTED '), 'PeerState DIAMETER_CONNECTED space after' );

done_testing();
