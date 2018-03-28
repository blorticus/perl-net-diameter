use Test::More;

use strict;
use warnings;

BEGIN { use_ok 'Diameter::Dictionary' };

my $yaml_string =<<EOY;
---
MessageTypes:
   - Code: 257
     ApplicationId: 0
     Proxiable: false
     Request:
         Name: "Capabilities-Exchange-Request"
         AbbreviatedName: "CER"
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

my $d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with Message definitions and all corresponding AVP definitions succeeds" );

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


done_testing();
