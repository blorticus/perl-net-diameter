use Test::More;

use strict;
use warnings;

BEGIN { use_ok( 'Diameter::Message' ) };
use Diameter::Dictionary;


$@ = ''; ok( !Diameter::Message->new()                         && $@ =~ /^Missing Parameter Exception/, 'Diameter::Message->new with no params fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => '' )      && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new( CommandCode => "" ) fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => undef )   && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new( CommandCode => undef ) fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 'foo' )   && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new( CommandCode => "foo" ) fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => -1 )      && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new( CommandCode => -1 ) fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 2**32+2 ) && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new( CommandCode => 2**32+2 ) fails' );

$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => '' )       && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => "" fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => -1 )       && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => -1 fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => 2**32+2 )  && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => 2**32+2 fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => 'foo' )    && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => "foo" fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => '23foo' )  && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => "23foo" fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => '23 foo' ) && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => "23 foo" fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => 'foo23' )  && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => "foo23" fails' );
$@ = ''; ok( !Diameter::Message->new( CommandCode => 257, ApplicationId => 'foo 23' ) && $@ =~ /^Invalid Parameter Exception/, 'Diameter::Message->new with ApplicationId => "foo 23" fails' );

my $msg = Diameter::Message->new(
    CommandCode     => 272,
);

# defaults are: ApplicationId => 0, IsProxiable => 1, IsRequest => 0, IsError => 0, IsPotentialRetransmit => 0, HbHId => 0, EtEId => 0, no AVPs
check_msg_values( $msg, 272, 0, 0x40, 0, 0, 0, 20, "0100001440000110000000000000000000000000", "Bare CCA" );

$msg = Diameter::Message->new(
    CommandCode     => 257,
    IsRequest       => 1,
    IsProxiable     => 0,
);

check_msg_values( $msg, 257, 0, 0x80, 1, 0, 0, 20, "0100001480000101000000000000000000000000", "Bare CER" );

$msg = Diameter::Message->new(
    CommandCode     => 272,
    IsRequest       => 1,
    IsPotentialRetransmit => 1,
    HopByHopId      => 0x12345678,
    EndToEndId      => 0xffee1100,
);

check_msg_values( $msg, 272, 0, 0xc0, 1, 0x12345678, 0xffee1100, 20, "01000014c00001100000000012345678ffee1100", "CER header only" );

$msg = Diameter::Message->new(
    CommandCode     => 272,
    IsRequest       => 1,
    IsPotentialRetransmit => 1,
    HopByHopId      => 0x12345678,
    EndToEndId      => 0xffee1100,
    Avps            => [],
);

check_msg_values( $msg, 272, 0, 0xc0, 1, 0x12345678, 0xffee1100, 20, "01000014c00001100000000012345678ffee1100", "CER header only, but empty Avp provided" );

$msg = Diameter::Message->new(
    CommandCode     => 257,
    IsRequest       => 1,
    IsPotentialRetransmit => 1,
    HopByHopId      => 0x12345678,
    EndToEndId      => 0xffee1100,
    Avps            => [
        { Code => 264, IsMandatory => 1, DataType => 'DiameterIdentity', Data => 'test.f5demo.com' },
        [ 0, 296, 1, 'DiameterIdentity', 'f5demo.com' ],
        Diameter::Message::AVP->new( Code => 257, IsMandatory => 1, DataType => 'Address', Data => '192.168.25.1' ),
        { Code => 266, IsMandatory => 1, DataType => 'Unsigned32', Data => 5544 },
        [qw( 0 269 1 UTF8String test-harness )],
    ],
);

check_msg_values( $msg, 257, 0, 0xc0, 1, 0x12345678, 0xffee1100, 112, "01000070c00001010000000012345678ffee11000000010840000017746573742e663564656d6f2e636f6d000000012840000012663564656d6f2e636f6d0000000001014000000e0001c0a8190100000000010a4000000c000015a80000010d40000014746573742d6861726e657373", "CER header and basic AVP list" );

my @avps = $msg->avps_by_code( 264 );
cmp_ok( @avps, '==', 1, 'CER header and basic AVP list avps_by_code( 264 )' );

@avps = $msg->avps_by_code( 269 );
cmp_ok( @avps, '==', 1, 'CER header and basic AVP list avps_by_code( 269 )' );

@avps = $msg->avps_by_code( 279 );
cmp_ok( @avps, '==', 0, 'CER header and basic AVP list avps_by_code( 279 )' );

done_testing();


sub check_msg_values {
    my ($msg, $code, $appid, $flags, $is_request, $hop_by_hop_id, $end_to_end_id, $expected_length, $expected_encoding_hex, $testname) = @_;

    cmp_ok( $msg->version,          '==', 1,                    "($testname) version" );
    cmp_ok( $msg->command_code,     '==', $code,                "($testname) code" );
    cmp_ok( $msg->application_id,   '==', $appid,               "($testname) application_id" );
    cmp_ok( $msg->flags,            '==', $flags,               "($testname) flags" );
    cmp_ok( $msg->end_to_end_id,    '==', $end_to_end_id,       "($testname) end_to_end_id" );
    cmp_ok( $msg->hop_by_hop_id,    '==', $hop_by_hop_id,       "($testname) hop_by_hop_id" );
    cmp_ok( $msg->msg_length,       '==', $expected_length,     "($testname) msg_length" );
    ok( ($is_request ? $msg->is_request : !$msg->is_request),   "($testname) is_request" );
    cmp_ok( unpack( "H*", $msg->encode ), 'eq', $expected_encoding_hex, "($testname) encode" );
}
