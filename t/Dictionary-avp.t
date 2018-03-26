use Test::More;

use strict;
use warnings;

BEGIN { use_ok( 'Diameter::Dictionary' ) }

my $yaml_string =<<EOY;
---
AvpTypes:
   - Code: 1419
     VendorId: 10415
     Names: ["Item-Number"]
     Type: "Unsigned32"
   - Code: 1447
     VendorId: 10415
     Names: ["RAND"]
     Type: "OctetString"
   - Code: 1454
     VendorId: 10415
     Names: ["SRES"]
     Type: "OctetString"
   - Code: 1416
     VendorId: 10415
     Type: "Grouped"
     Names: ["GERAN-Vector"]
     ChildAvps:
        - VendorId: 10415
          Code: 1419
          Count: "*"
        - Name: "RAND"
          Count: "1"
        - VendorId: 10415
          Code: 1454
          Count: "1"
        - Name: "Kc"
          Count: "1"
EOY

my $d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only single simple MessageType stanza succeeds" );

$yaml_string =<<EOY;
---
AvpTypes:
   - Code: 1
     Names: ["User-Name"]
     Type: "UTF8String"
   - Code: 25
     Names: ["Class"]
     Type: "OctetString"
   - Code: 257
     Names: ["Host-IP-Address"]
     Type: "Address"
   - Code: 258
     Names: ["Auth-Application-Id"]
     Type: "Unsigned32"
   - Code: 259
     Names: ["Acct-Application-Id"]
     Type: "Unsigned32"
   - Code: 260
     Names: ["Vendor-Specific-Application-Id"]
     Type: "Grouped"
   - Code: 602
     Names: ["Server-Name"]
     VendorId: 10415
     Type: "UTF8String"
   - Code: 1524
     VendorId: 10415
     Type: "UTF8String"
     Names: ["SSID"]
   - Code: 1419
     VendorId: 10415
     Names: ["Item-Number"]
     Type: "Unsigned32"
   - Code: 1447
     VendorId: 10415
     Names: ["RAND"]
     Type: "OctetString"
   - Code: 1454
     VendorId: 10415
     Names: ["SRES"]
     Type: "OctetString"
   - Code: 1453
     VendorId: 10415
     Names: ["Kc"]
     Type: "OctetString"
   - Code: 1416
     VendorId: 10415
     Type: "Grouped"
     Names: ["GERAN-Vector"]
     ChildAvps:
        - VendorId: 10415
          Code: 1419
          Count: "*"
        - Name: "RAND"
          Count: "1"
        - VendorId: 10415
          Code: 1454
          Count: "1"
        - Name: "Kc"
          Count: "1"
EOY


done_testing();
