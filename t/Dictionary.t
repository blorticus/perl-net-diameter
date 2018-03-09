use Test::More;

use strict;
use warnings;

BEGIN { use_ok( 'Diameter::Dictionary' ) }

ok( !Diameter::Dictionary->new(), "Diameter\:\:Dictionary->new() returns undef" );
ok( !Diameter::Dictionary->new( FromString => undef ), "Diameter\:\:Dictionary->new() FromString cannot be undef" );
ok( !Diameter::Dictionary->new( FromFile => undef ), "Diameter\:\:Dictionary->new() FromFile cannot be undef" );
ok( !Diameter::Dictionary->new( FromFile => "" ), "Diameter\:\:Dictionary->new() FromFile cannot be empty string" );
ok( !Diameter::Dictionary->new( FromFoo => "this" ), "Diameter\:\:Dictionary->new() FromFile or FromString must be defined" );

ok( !Diameter::Dictionary->new( FromString => "" ), "Diameter\:\:Dictionary->new() cannot have FromString be empty" );
ok( !Diameter::Dictionary->new( FromString => "---\n" ), "Diameter\:\:Dictionary->new() string cannot be empty yaml" );
ok( !Diameter::Dictionary->new( FromString => "---\nFoo:\nBar:\n  - This: that\n" ), "Diameter\:\:Dictionary->new() string must define MessageTypes or AvpTypes" );

my $yaml_string =<<EOY1;
---
MessageTypes:
EOY1

my $d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only MessageTypes stanza succeeds" );

$yaml_string =<<EOY2;
---
MessageTypes:
   - Code: 272
     ApplicationId: 0
     Proxiable: false
     Request:
         Names: ["Capabilities-Exchange-Request", "CER"]
         AvpOrder: []
         MandatoryAvps: []
         OptionalAvps: []
     Answer:
         Names: ["Capabilities-Exchange-Answer", "CEA"]
         AvpOrder: []
         MandatoryAvps: []
         OptionalAvps: []
EOY2

$d = Diameter::Dictionary->new( FromString => $yaml_string );
ok( defined $d && ref $d, "Diameter\:\:Dictionary->new() with only single simple MessageType  stanza succeeds" );


done_testing();
