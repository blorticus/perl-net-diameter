package Diameter::Dictionary;

use YAML::XS;
$YAML::XS::LoadBlessed = 0;

use strict;
use warnings;

use FileHandle;

#
# $d = Diameter::Dictionary->new( FromFile => $filepath, FromString => $string );
# $m = $d->message( Name => $name | Code => $code | (Code => $code, ApplicationId => $appid), Avps => [ $d->avp( $name, $value ), ... ] ) or die $@;
# %v = $d->describe_message( Name => $name | Code => $code | (Code => $code, ApplicationId => $appid );
# %v = $d->describe_avp( Name => $name | Code => $code | (Code => $code, VendorId => $vendorid) ); 
#

#
# MessageTypes:
#    - Code: 272
#      ApplicationId: 0
#      Proxiable: false
#      Request:
#          Names: ["Capabilities-Exchange-Request", "CER"]
#          AvpOrder: ["..."]
#          MandatoryAvps: ["..."]
#          OptionalAvps: ["..."]
#      Answer:
#          Names: ["Capabilities-Exchange-Request", "CER"]
#          AvpOrder: ["..."]
#          MandatoryAvps: ["..."]
#          OptionalAvps: ["..."]
#
# AvpTypes:
#    - Code: 264
#      VendorId: 0
#      Name: "Origin-Host"
#      Type: "DiamIdent"
#

use constant {

};


sub new {
    my $class = shift;
    my %params = @_;

    my $yaml_string;

    if (exists $params{FromFile} && defined $params{FromFile} && $params{FromFile} ne "") {
        if (!-f $params{FromFile}) {
            $@ = "File ($params{FromFile}) does not exist";
            return undef;
        }
        if (!-R $params{FromFile}) {
            $@ = "File ($params{FromFile} is not readable";
            return undef;
        }

        my $fh = new FileHandle $params{FromFile}
            or do {
                $@ = "Failed to open file ($params{FromFile}) for reading: $!";
                return undef;
            };

        $yaml_string = join "", (<$fh>);

        $fh->close;
    }
    elsif (exists $params{FromString} && defined $params{FromString}) {
        $yaml_string = $params{FromString};
    }
    else {
        $@ = "Invalid paramaters";
        return undef;
    }

    my $yaml_ds = Load $yaml_string
        or do {
            $@ = "Invalid yaml: $@";
            return undef;
        };

    $class->_validate_yaml_datastructure( $yaml_ds )
        or do {
            $@ = "YAML parse error: $@";
            return undef;
        };

    return bless [

    ], $class;
}


#   'Messages' => ARRAY(0x2c10d48)
#      0  HASH(0x2af5958)
#         'MessageType' => HASH(0x2c202a0)
#            'Answer' => HASH(0x2ca4ce0)
#               'AvpOrder' => ARRAY(0x2ca4de8)
#                    empty array
#               'MandatoryAvps' => ARRAY(0x2ca4e48)
#                    empty array
#               'Names' => ARRAY(0x2c69b50)
#                  0  'Capabilities-Exchange-Answer'
#                  1  'CEA'
#               'OptionalAvps' => ARRAY(0x2ca4ed8)
#                    empty array
#            'ApplicationId' => 0
#            'Code' => 272
#            'Proxiable' => ''
#            'Request' => HASH(0x2c5d9c0)
#               'AvpOrder' => ARRAY(0x2c696b8)
#                    empty array
#               'MandatoryAvps' => ARRAY(0x2c5dea0)
#                    empty array
#               'Names' => ARRAY(0x2c47ac8)
#                  0  'Capabilities-Exchange-Request'
#                  1  'CER'
#               'OptionalAvps' => ARRAY(0x2c5e290)
#                    empty array


# need to track whether required, what type must be, default value if not present

use constant {
    E_IS_REQUIRED       => 0,
    E_TYPE              => 1,
    E_DEFAULT_VALUE     => 2,
    E_CHILDREN          => 3,
};

my %element_structure = (
    MessageTypes => [0, 'HASH', {}, {
        ApplicationId => [0, 'uint32', 0],
        Code          => [1, 'uint32', undef],
        Proxiable     => [0, 'bool', 1],
        Error         => [0, 'bool', 0],
        Request       => [0, 'HASH', {}, {
            Names           => [1, 'ARRAY', undef],
            AvpOrder        => [0, 'ARRAY', []],
            MandatoryAvps   => [0, 'ARRAY', []],
            OptionalAvps    => [0, 'ARRAY', []],
        }],
        Answer        => [0, 'HASH', {}, {
            Names           => [1, 'ARRAY', undef],
            AvpOrder        => [0, 'ARRAY', []],
            MandatoryAvps   => [0, 'ARRAY', []],
            OptionalAvps    => [0, 'ARRAY', []],
        }],
    }],
);

my %yaml_boolean_table = (
    Yes   => 1,
    YES   => 1,
    n     => 0,
    N     => 0,
    no    => 0,
    No    => 0,
    NO    => 0,
    true  => 1,
    True  => 1,
    TRUE  => 1,
    false => 0,
    False => 0,
    FALSE => 0,
    on    => 1,
    On    => 1,
    ON    => 1,
    off   => 0,
    Off   => 0,
    OFF   => 0,
);

sub _validate_yaml_element {
    my $class = shift;
    my ($node_name, $element_value, $structure_def_ar) = @_;

    my ($is_required, $required_type, $default_value, $struct_children) = @{ $structure_def_ar };

    my $element_type = ref $element_value;

    if ($required_type eq "bool") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be YAML boolean";
            return 0;
        }

        if (!exists $yaml_boolean_table{$element_value}) {
            $@ = "For ($node_name) value must be YAML boolean";
            return 0;
        }
    }
    elsif ($required_type eq "uint32") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be YAML boolean";
            return 0;
        }

        unless ($element_value =~ /^\d+/ && $element_value < 2**32) {
            $@ = "For ($node_name) value must be uint32";
            return 0;
        }
    }
    elsif ($required_type eq "ARRAY") {
        unless ($element_type eq "ARRAY") {
            $@ = "For ($node_name) value must be a YAML list";
            return 0;
        }
    }
    elsif ($required_type eq "HASH") {
        unless ($element_type eq "HASH") {
            $@ = "For ($node_name) value must be a YAML map";
            return 0;
        }

        if (defined $struct_children) {
            my %child_elements = (map { $_ => 1 } (keys %{ $element_value }));

            foreach my $struct_child_key (keys %{ $struct_children }) {
                if ($struct_children->{$struct_child_key}->[E_IS_REQUIRED]) {
                    if (!exists $child_elements{$struct_child_key}) {
                        $@ = "For ($node_name) must have child ($struct_child_key)";
                        return 0;
                    }
                }

                my $r = $class->_validate_yaml_element( "$node_name/$struct_child_key", $element_value->{$struct_child_key}, $struct_children->{$struct_child_key} );

                if (!$r) {

                }

                delete $child_elements{$struct_child_key};
            }

            my @remaining_keys = keys %child_elements;

            if (@remaining_keys) {
                $@ = "For ($node_name), unknown child element ($remaining_keys[0])";
                return 0;
            }
        }
        elsif (keys %{ $element_value }) {
            $@ = "For ($node_name), there must be no children";
            return 0;
        }
    }

    return 1;
}

sub _validate_yaml_datastructure {
    my $class = shift;
    my $yaml_ds = shift;

    if (!defined $yaml_ds || !ref $yaml_ds || ref $yaml_ds ne "HASH") {
        $@ = "Invalid top level structure";
        return 0;
    }

    if (!exists $yaml_ds->{MessageTypes} && !exists $yaml_ds->{AvpTypes}) {
        $@ = "Neither MessageTypes nor AvpTypes defined";
        return 0;
    }

    my $struct_ok = 0;
    if (exists $yaml_ds->{MessageTypes}) {
        if (!defined $yaml_ds->{MessageTypes} || scalar( keys( %{ $yaml_ds->{MessageTypes} } ) ) == 0) {
            $yaml_ds->{MessageTypes} = {};
            $struct_ok = 1;
        }
        else {
            $struct_ok = $class->_validate_yaml_element( "MessageTypes", $yaml_ds->{MessageTypes}, $element_structure{MessageTypes} );
        }
    }

    if (exists $yaml_ds->{AvpTypes}) {
    }

    return $struct_ok;;
}


sub message {

}

sub avp {

}

sub describe_message {

}

sub describe_avp {

}


1;
