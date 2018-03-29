use Test::More;

BEGIN { use_ok 'Diameter::Dictionary' };
use Diameter::Message;
use Diameter::Message::AVP;

use strict;
use warnings;

my $yaml_string =<<EOY;
---
MessageTypes:
   - Code: 257
     ApplicationId: 0
     Request:
         Name: "Capabilities-Exchange-Request"
         AbbreviatedName: "CER"
         Proxiable: false
         AvpOrder:
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address
            - Vendor-Id
            - Product-Name
            - Origin-State-Id
            - Supported-Vendor-Id
            - Auth-Application-Id
            - Inband-Security-Id
            - Acct-Application-Id
            - Vendor-Specific-Application-Id
            - Firmware-Revision
            - AVP
         MandatoryAvps:
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address:1*
            - Vendor-Id
            - Product-Name
         OptionalAvps:
            - Origin-State-Id
            - Supported-Vendor-Id:*
            - Auth-Application-Id:*
            - Inband-Security-Id:*
            - Acct-Application-Id:*
            - Vendor-Specific-Application-Id:*
            - Firmware-Revision
            - AVP:*
     Answer:
         Name: "Capabilities-Exchange-Answer"
         AbbreviatedName: "CEA"
         Proxiable: false
         AvpOrder:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address
            - Vendor-Id
            - Product-Name
            - Origin-State-Id
            - Error-Message
            - Failed-AVP
            - Supported-Vendor-Id
            - Auth-Application-Id
            - Inband-Security-Id
            - Acct-Application-Id
            - Vendor-Specific-Application-Id
            - Firmware-Revision
            - AVP
         MandatoryAvps:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Host-IP-Address:1*
            - Vendor-Id
            - Product-Name
         OptionalAvps:
            - Origin-State-Id
            - Error-Message
            - Failed-AVP
            - Supported-Vendor-Id:*
            - Auth-Application-Id:*
            - Inband-Security-Id:*
            - Acct-Application-Id:*
            - Vendor-Specific-Application-Id:*
            - Firmware-Revision
            - AVP:*
   - Code: 282
     ApplicationId: 0
     Proxiable: false
     Request:
         Name: "Disconnect-Peer-Request"
         AbbreviatedName: "DPR"
         AvpOrder:
            - Origin-Host
            - Origin-Realm
            - Disconnect-Cause
            - AVP
         MandatoryAvps:
            - Origin-Host
            - Origin-Realm
            - Disconnect-Cause
         OptionalAvps:
            - AVP:*
     Answer:
         Name: "Disconnect-Peer-Answer"
         AbbreviatedName: "DPA"
         AvpOrder:
            - Result-Code
            - Origin-Host
            - Origin-Realm
            - Error-Message
            - Failed-AVP
            - AVP
         MandatoryAvps:
            - Result-Code
            - Origin-Host
            - Origin-Realm
         OptionalAvps:
            - Error-Message
            - Failed-AVP
            - AVP:*
AvpTypes:
   - Code: 1
     Name: "User-Name"
     Type: "UTF8String"
   - Code: 25
     Name: "Class"
     Type: "OctetString"
   - Code: 27
     Name: "Session-Timeout"
     Type: "Unsigned32"
   - Code: 33
     Name: "Proxy-State"
     Type: "OctetString"
   - Code: 44
     Name: "Accounting-Session-Id"
     Type: "OctetString"
   - Code: 50
     Name: "Acct-Multi-Session-Id"
     Type: "UTF8String"
   - Code: 55
     Name: "Event-Timestamp"
     Type: "Time"
   - Code: 85
     Name: "Acct-Interim-Interval"
     Type: "Unsigned32"
   - Code: 257
     Name: "Host-IP-Address"
     Type: "Address"
   - Code: 258
     Name: "Auth-Application-Id"
     Type: "Unsigned32"
   - Code: 259
     Name: "Acct-Application-Id"
     Type: "Unsigned32"
   - Code: 260
     Name: "Vendor-Specific-Application-Id"
     Type: "Grouped"
   - Code: 261
     Name: "Redirect-Host-Usage"
     Type: "Enumerated"
   - Code: 262
     Name: "Redirect-Max-Cache-Time"
     Type: "Unsigned32"
   - Code: 263
     Name: "Session-Id"
     Type: "UTF8String"
   - Code: 264
     Name: "Origin-Host"
     Type: "DiameterIdentity"
   - Code: 265
     Name: "Supported-Vendor-Id"
     Type: "Unsigned32"
   - Code: 266
     Name: "Vendor-Id"
     Type: "Unsigned32"
   - Code: 267
     Name: "Firmware-Revision"
     Type: "Unsigned32"
   - Code: 268
     Name: "Result-Code"
     Type: "Unsigned32"
   - Code: 269
     Name: "Product-Name"
     Type: "UTF8String"
   - Code: 270
     Name: "Session-Binding"
     Type: "Unsigned32"
   - Code: 271
     Name: "Session-Server-Failover"
     Type: "Enumerated"
   - Code: 272
     Name: "Multi-Round-Time-Out"
     Type: "Unsigned32"
   - Code: 273
     Name: "Disconnect-Cause"
     Type: "Enumerated"
   - Code: 274
     Name: "Auth-Request-Type"
     Type: "Enumerated"
   - Code: 276
     Name: "Auth-Grace-Period"
     Type: "Unsigned32"
   - Code: 277
     Name: "Auth-Session-State"
     Type: "Enumerated"
   - Code: 278
     Name: "Origin-State-Id"
     Type: "Unsigned32"
   - Code: 279
     Name: "Failed-AVP"
     Type: "Grouped"
   - Code: 280
     Name: "Proxy-Host"
     Type: "DiameterIdentity"
   - Code: 281
     Name: "Error-Message"
     Type: "UTF8String"
   - Code: 282
     Name: "Route-Record"
     Type: "DiameterIdentity"
   - Code: 283
     Name: "Destination-Realm"
     Type: "DiameterIdentity"
   - Code: 284
     Name: "Proxy-Info"
     Type: "Grouped"
   - Code: 285
     Name: "Re-Auth-Request-Type"
     Type: "Enumerated"
   - Code: 287
     Name: "Accounting-Sub-Session-Id"
     Type: "Unsigned64"
   - Code: 291
     Name: "Authorization-Lifetime"
     Type: "Unsigned32"
   - Code: 292
     Name: "Redirect-Host"
     Type: "DiameterURI"
   - Code: 293
     Name: "Destination-Host"
     Type: "DiameterIdentity"
   - Code: 294
     Name: "Error-Reporting-Host"
     Type: "DiameterIdentity"
   - Code: 295
     Name: "Termination-Cause"
     Type: "Enumerated"
   - Code: 296
     Name: "Origin-Realm"
     Type: "DiameterIdentity"
   - Code: 297
     Name: "Experimental-Result"
     Type: "Grouped"
   - Code: 298
     Name: "Experimental-Result-Code"
     Type: "Unsigned32"
   - Code: 299
     Name: "Inband-Security-Id"
     Type: "Unsigned32"
   - Code: 300
     Name: "E2E-Sequence"
     Type: "Grouped"
   - Code: 480
     Name: "Accounting-Record-Type"
     Type: "Enumerated"
   - Code: 483
     Name: "Accounting-Realtime-Required"
     Type: "Enumerated"
   - Code: 485
     Name: "Accounting-Record-Number"
     Type: "Unsigned32"
EOY

my $d = Diameter::Dictionary->from_yaml( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->from_yaml() with Message definitions and all corresponding AVP definitions succeeds" );

my $avp = Diameter::Message::AVP->new( Code => 264, Data => "foo.example.com" );
ok( defined $avp && ref $avp, 'Created unexpanded Origin-Host AVP' );
ok( !$d->is_expanded_avp( $avp ), 'Origin-Host AVP is unexpanded' );
ok( !$avp->can('name'), 'Unexpanded Origin-Host AVP has no name' );
cmp_ok( unpack( "H*", $avp->encode ), 'eq', '0000010800000017666f6f2e6578616d706c652e636f6d00', 'Unexpanded Origin-Host AVP encode check' );

$avp = $d->expand_avp( $avp );

ok( defined $avp && ref $avp, 'exapand_avp on Origin-Host AVP without error' );
ok( $d->is_expanded_avp( $avp ), 'Origin-Host AVP is now expanded' );
ok( $avp->can('name'), 'Expanded Origin-Host AVP has name' );
cmp_ok( $avp->name, 'eq', 'Origin-Host', 'Expanded Origin-Host name is Origin-Host' );
cmp_ok( $avp->data, 'eq', 'foo.example.com', 'Expanded Origin-Host data check' );
cmp_ok( unpack( "H*", $avp->encode ), 'eq', '0000010800000017666f6f2e6578616d706c652e636f6d00', 'Expanded Origin-Host AVP encode check' );


$avp = Diameter::Message::AVP->new( Code => 258, Data => pack( "N", 16777254 ), IsMandatory => 1 );
ok( defined $avp && ref $avp, 'Created unexpanded Auth-Application-Id AVP' );
ok( !$d->is_expanded_avp( $avp ), 'Auth-Application-Id AVP is unexpanded' );
ok( !$avp->can('name'), 'Unexpanded Auth-Application-Id AVP has no name' );
cmp_ok( unpack( "H*", $avp->encode ), 'eq', '000001024000000c01000026', 'Unexpanded Auth-Application-Id AVP encode check' );

$avp = $d->expand_avp( $avp );

ok( defined $avp && ref $avp, 'exapand_avp on Auth-Application-Id AVP without error' );
ok( $d->is_expanded_avp( $avp ), 'Auth-Application-Id AVP is now expanded' );
ok( $avp->can('name'), 'Expanded Auth-Application-Id AVP has name' );
cmp_ok( $avp->name, 'eq', 'Auth-Application-Id', 'Expanded Auth-Application-Id name is Auth-Application-Id' );
cmp_ok( $avp->data, '==', 16777254, 'Expanded Auth-Application-Id data check' );
cmp_ok( $avp->raw_data, 'eq', pack( "N", 16777254 ), 'Expanded Auth-Application-Id raw data check' );
cmp_ok( unpack( "H*", $avp->encode ), 'eq', '000001024000000c01000026', 'Expanded Auth-Application-Id AVP encode check' );


my $m = Diameter::Message->new( CommandCode => 257, IsRequest => 1, IsProxiable => 0, HopByHopId => 0x10101010, EndToEndId => 0x0a2b, Avps => [] );

ok( defined $m && ref $m, 'Construct unexpanded CER message without AVPs' );
ok( !$d->is_expanded_message( $m ), 'Unexpanded CER message is_expanded_message check' );
ok( !$m->can('name'), 'Unexpanded CER message check for name method' );
ok( !$m->can('abbreviated_name'), 'Unexpanded CER message check for abbreviated_name method' );
cmp_ok( unpack( "H*", $m->encode ), 'eq', '0100001480000101000000001010101000000a2b', 'Unexpanded CER message encode check' );

$m = $d->expand_message( $m );

ok( defined $m && ref $m, 'expand_message on unexpanded CER message without AVPs' );
ok( $d->is_expanded_message( $m ), 'Expanded CER message is_expanded_message check' );
ok( $m->can('name'), 'Expanded CER message check for name method' );
ok( $m->can('abbreviated_name'), 'Expanded CER message check for abbreviated_name method' );
cmp_ok( $m->name, 'eq', 'Capabilities-Exchange-Request', 'Expanded CER message check for name' );
cmp_ok( $m->abbreviated_name, 'eq', 'CER', 'Expanded CER message check for abbreviated name' );
cmp_ok( unpack( "H*", $m->encode ), 'eq', '0100001480000101000000001010101000000a2b', 'Expanded CER message encode check' );


# this type isn't in the dictionary
$m = Diameter::Message->new( CommandCode => 1010, IsRequest => 1, IsProxiable => 0, HopByHopId => 0x10101010, EndToEndId => 0x0a2b, Avps => [] );

ok( defined $m && ref $m, 'Construct unexpanded message having CommandCode => 1010, without AVPs' );
ok( !$d->is_expanded_message( $m ), 'Unexpanded message having CommandCode => 1010 is_expanded_message check' );
ok( !$m->can('name'), 'Unexpanded message having CommandCode => 1010 check for name method' );
ok( !$m->can('abbreviated_name'), 'Unexpanded message having CommandCode => 1010 check for abbreviated_name method' );

my $nm = $d->expand_message( $m );

cmp_ok( $nm, 'eq', $m, 'expand_message check on unexpanded message having CommandCode => 1010 (not in dictionary)' );


# with AVPs but out of order
$m = Diameter::Message->new(
        CommandCode => 257,
        IsRequest   => 1,
        IsProxiable => 0,
        Avps => [
            Diameter::Message::AVP->new( Code => 257, EncodedData => pack( "CCCCCC", 0, 1, 192, 168, 1, 1 ) ),
            Diameter::Message::AVP->new( Code => 264, EncodedData => "test.example.com", IsMandatory => 1 ),
            Diameter::Message::AVP->new( Code => 266, EncodedData => pack( "N", 1010 ) ),
            Diameter::Message::AVP->new( Code => 296, EncodedData => "example.com", IsMandatory => 1 ),
            Diameter::Message::AVP->new( Code => 269, EncodedData => "tester" ),
        ]
);

ok( defined $m && ref $m && $m->isa( 'Diameter::Message' ), 'construction of unexpanded CER with out-of-order mandatory AVPs' );

# spaces in encoding on word boundaries.  Makes it easier to debug
my $expected_encoding = join( "", split( / /,
                       # Message header
                   "0100006c 80000101 00000000 00000000 00000000" .
                       # AVP: Host-IP-Address
                   "00000101 0000000e 0001c0a8 01010000" .
                       # AVP: Origin-Host
                   "00000108 40000018 74657374 2e657861 6d706c65 2e636f6d" .
                       # AVP: Vendor-Id
                   "0000010a 0000000c 000003f2" .
                       # AVP: Origin-Realm
                   "00000128 40000013 6578616d 706c652e 636f6d00" .
                       # AVP: Product-Name
                   "0000010d 0000000e 74657374 65720000" ) );

cmp_ok( unpack( "H*", $m->encode ), 'eq', $expected_encoding, 'encoding of unexpanded CER with out-of-order mandatory AVPs' );

$m = $d->expand_message( $m );

ok( defined $m && ref $m, 'expand_message on expanded CER with out-of-order mandatory AVPs' );
ok( $d->is_expanded_message( $m ), 'is_expanded_message check on expanded CER with out-of-order mandatory AVPs' );
ok( $m->can('name'), 'can("name") check on expanded CER with out-of-order mandatory AVPs' );
ok( $m->can('abbreviated_name'), 'can("name") check on expanded CER with out-of-order mandatory AVPs' );
cmp_ok( $m->name, 'eq', 'Capabilities-Exchange-Request', 'name check on expanded CER with out-of-order mandatory AVPs' );
cmp_ok( $m->abbreviated_name, 'eq', 'CER', 'abbreviated_name check on expanded CER with out-of-order mandatory AVPs' );
cmp_ok( unpack( "H*", $m->encode ), 'eq', $expected_encoding, 'encoding check on expanded CER with out-of-order mandatory AVPs' );

my @expected_avp_info = ( ['Host-IP-Address', 'eq', '192.168.1.1'],
                          ['Origin-Host',     'eq', 'test.example.com'],
                          ['Vendor-Id',       '==', 1010],
                          ['Origin-Realm',    'eq', 'example.com'],
                          ['Product-Name',    'eq', 'tester'] );

cmp_ok( $m->avps, '==', @expected_avp_info, 'AVP count check on expanded CER with out-of-order mandatory AVPs' );

foreach (my $i = 0; $i < @expected_avp_info; $i++) {
    my ($name, $op, $value) = @{ $expected_avp_info[$i] };
    my $avp = ($m->avps)[$i];

    ok( $d->is_expanded_avp( $avp ), 'is_expanded_check on AVP number ' . ($i + 1) . ' for expanded CER with out-of-order mandatory AVPs' );
    cmp_ok( $avp->name, 'eq', $name,  'name check on AVP number ' . ($i + 1) . ' for expanded CER with out-of-order mandatory AVPs' );
    cmp_ok( $avp->data, $op,  $value, 'value check on AVP number ' . ($i + 1) . ' for expanded CER with out-of-order mandatory AVPs' );
}


done_testing();
