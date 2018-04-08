use Test::More;

use strict;
use warnings;

BEGIN { use_ok 'Diameter::Dictionary' };

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
     Request:
         Name: "Disconnect-Peer-Request"
         AbbreviatedName: "DPR"
         Proxiable: false
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
   - Code: 8388635
     ApplicationId: 16777302
     Request:
        Name: Sy-Spending-Limit-Request
        AbbreviatedName: Sy-SLR
        Proxiable: true
        AvpOrder:
            - Session-Id
            - Auth-Application-Id
            - Origin-Host
            - Origin-Realm
            - Destination-Realm
            - Destination-Host
            - Origin-State-Id
            - SL-Request-Type
            - Subscription-Id
            - Policy-Counter-Identifier
            - Proxy-Info
            - Route-Record
            - AVP
        MandatoryAvps: ["Session-Id", "Auth-Application-Id", "Origin-Host", "Origin-Realm", "Destination-Realm", "SL-Request-Type"]
        OptionalAvps:
            - Destination-Host
            - Origin-State-Id
            - Subscription-Id:*
            - Policy-Counter-Identifier:*
            - Proxy-Info:*
            - Route-Record:*
            - AVP:*
     Answer:
        Name: Sy-Spending-Limit-Answer
        AbbreviatedName: Sy-SLA
        Proxiable: true
        AvpOrder:
            - Session-Id
            - Auth-Application-Id
            - Origin-Host
            - Origin-Realm
            - Result-Code
            - Experimental-Result
            - Policy-Counter-Status-Report
            - Error-Message
            - Error-Reporting-Host
            - Failed-AVP
            - Origin-State-Id
            - Redirect-Host
            - Redirect-Host-Usage
            - Redirect-Max-Cache-Time
            - Proxy-Info
            - AVP
        MandatoryAvps: ["Session-Id", "Auth-Application-Id", "Origin-Host", "Origin-Realm"]
        OptionalAvps:
            - Result-Code
            - Experimental-Result
            - Policy-Counter-Status-Report:*
            - Error-Message
            - Error-Reporting-Host
            - Failed-AVP:*
            - Origin-State-Id
            - Redirect-Host:*
            - Redirect-Host-Usage
            - Redirect-Max-Cache-Time
            - Proxy-Info:*
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
   - Code: 443
     VendorId: 0
     Name: "Subscription-Id"
     Type: "Grouped"
   - Code: 444
     VendorId: 0
     Name: "Subscription-Id-Data"
     Type: "UTF8String"
   - Code: 450
     VendorId: 0
     Name: "Subscription-Id-Type"
     Type: "Enumerated"
   - Code: 480
     Name: "Accounting-Record-Type"
     Type: "Enumerated"
   - Code: 483
     Name: "Accounting-Realtime-Required"
     Type: "Enumerated"
   - Code: 485
     Name: "Accounting-Record-Number"
     Type: "Unsigned32"
   - Code: 2901
     VendorId: 10415
     Name: "Policy-Counter-Identifier"
     Type: "UTF8String"
   - Code: 2902
     VendorId: 10415
     Name: "Policy-Counter-Status"
     Type: "UTF8String"
   - Code: 2903
     VendorId: 10415
     Name: "Policy-Counter-Status-Report"
     Type: "Grouped"
   - Code: 2904
     VendorId: 10415
     Name: "SL-Request-Type"
     Type: "Enumerated"

EOY

my $d = Diameter::Dictionary->from_yaml( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->from_yaml() with Message definitions and all corresponding AVP definitions succeeds" );

ok( !$d->message( Foo => 'bar' ), 'Attempt to create Message with neither Name nor Code fails' );
ok( !$d->message( Name => "foo" ), 'Attempt to create Message with a name not in the dictionary fails' );
ok( !$d->message( Code => 10 ), 'Attempt to create Message with a code not in the dictionary fails' );
ok( !$d->message( ApplicationId => 109, Code => 272 ), 'Attempt to create Message with a application_id+code not in the dictionary fails' );

my $m = $d->message( Name => "CER", Avps => [
        HostIPAddress => "192.168.1.1",
        OriginHost => "test.example.com",
        VendorId => 1010,
        $d->avp( Name => "Origin-Realm", Value => "example.com" ),
        $d->avp( Name => "Product-Name", Value => "tester" ),
    ] );

ok( defined $m && ref $m && $m->isa( 'Diameter::Message' ), 'message() on CER with all but only mandatory AVPs creates Message object' );

# spaces in encoding on word boundaries.  Makes it easier to debug
my $expected_encoding = join( "", split( / /,
                       # Message header
                   "0100006c 80000101 00000000 00000000 00000000" .
                       # AVP: Origin-Host
                   "00000108 40000018 74657374 2e657861 6d706c65 2e636f6d" .
                       # AVP: Origin-Realm
                   "00000128 40000013 6578616d 706c652e 636f6d00" .
                       # AVP: Host-IP-Address
                   "00000101 4000000e 0001c0a8 01010000" .
                       # AVP: Vendor-Id
                   "0000010a 4000000c 000003f2" .
                       # AVP: Product-Name
                   "0000010d 4000000e 74657374 65720000" ) );

cmp_ok( unpack( "H*", $m->encode ), 'eq', $expected_encoding, 'message() on CER with all but only mandatory AVPs encodes correctly, including AVP re-ordering' );

$m = $d->message(
    Name        => "Sy-SLA",
    HopByHopId  => 0x1234,
    EndToEndId  => 0x2,
        Avps        => [
            SessionId           => "test.example.com;123456789;12345",
            ResultCode          => 2001,
            AuthApplicationId   => 16777302,
            OriginHost          => "test.example.com",
            OriginRealm         => "example.com",
            PolicyCounterStatusReport   => [
                PolicyCounterIdentifier         => 'TSSTI',
                PolicyCounterStatus             => 'LT',
            ],
            PolicyCounterStatusReport   => [
                PolicyCounterIdentifier         => 'SUBSCRIBER-BALANCE-STATUS',
                PolicyCounterStatus             => 'OK',
            ],
        ],
);

ok( defined $m && ref $m, 'message() on Sy-SLR with nested Grouped AVPs creates object' );

$expected_encoding = join( "", split( / /,
                        # Message header
                    "010000f4 4080001b 01000056 00001234 00000002" .
                        # AVP: Session-Id
                    "00000107 40000028 74657374 2e657861 6d706c65 2e636f6d 3b313233 34353637 38393b313 2333435" .
                        # AVP: Auth-Application-Id
                    "00000102 4000000c 01000056" .
                        # AVP: Origin-Host
                    "00000108 40000018 74657374 2e657861 6d706c65 2e636f6d" .
                       # AVP: Origin-Realm
                    "00000128 40000013 6578616d 706c652e 636f6d00" .
                        # AVP: Result-Code
                    "0000010c 0000000c 000007d1" .
                        # AVP: PolicyCountStatusReport [Grouped: PolicyCounterIdentifier+PolicyCounterStatus]
                    "00000b57 80000030 000028af" .
                        "00000b55 80000011 000028af 54535354 49000000" .
                        "00000b56 8000000e 000028af 4c540000" .
                        # AVP: PolicyCountStatusReport [Grouped: PolicyCounterIdentifier+PolicyCounterStatus]
                    "00000b57 80000044 000028af" .
                        "00000b55 80000025 000028af 53554253 43524942 45522d42 414c414e 43452d53 54415455 53000000" .
                        "00000b56 8000000e 000028af 4f4b0000" ) );

cmp_ok( unpack( "H*", $m->encode ), 'eq', $expected_encoding, 'message() on Sy-SLR with nested Grouped AVPs encodes as expected' );


done_testing();
