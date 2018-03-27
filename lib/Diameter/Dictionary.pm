package Diameter::Dictionary;

use YAML::XS;
$YAML::XS::LoadBlessed = 0;

use strict;
use warnings;

use FileHandle;
use Storable qw[dclone];


use constant {
    E_IS_REQUIRED       => 0,
    E_TYPE              => 1,
    E_DEFAULT_VALUE     => 2,
    E_CHILDREN          => 3,
};

# This describes what the serialized YAML datastructure (that is, the one created
# by YAML::XS from a YAML file/string) must look like.  Each element has a root
# name, and points to a listref.  That listref has the elements as noted above in
# the E_* constants: (0) is the element required at this location of the structure
# hierarchy?; (1) what is the required type for the value of this element (uint32,
# bool, map [hashref], list [listref], enum; (2) if this is not a required field,
# what is the default value (undef if there is no default, and the element is not
# auto-populated)?; (4) if the type is 'map', what are the child elements, and if the
# type is 'enum', what are the permitted string values?
#
# If the value for E_IS_REQUIRED is undef, and it is an element of a Map, and
# if no value is defined, then the element is not created in the resulting hashref
#
my %element_structure = (
    MessageTypes => [0, 'list', [], [1, 'map', {}, {
            ApplicationId => [0, 'uint32', 0],
            Code          => [1, 'uint32', undef],
            Proxiable     => [0, 'bool', 1],
            Error         => [0, 'bool', 0],
            Request       => [0, 'map', {}, {
                Name            => [1, 'string', undef],
                AbbreviatedName => [0, 'string', ''],
                AvpOrder        => [0, 'list', []],
                MandatoryAvps   => [0, 'list', []],
                OptionalAvps    => [0, 'list', []],
            }],
            Answer        => [0, 'map', {}, {
                Name            => [1, 'string', undef],
                AbbreviatedName => [0, 'string', ''],
                AvpOrder        => [0, 'list', []],
                MandatoryAvps   => [0, 'list', []],
                OptionalAvps    => [0, 'list', []],
            }],
        }],
    ],
    AvpTypes => [0, 'list', [], [1, 'map', {}, {
            Code        => [1, 'uint32', undef],
            VendorId    => [0, 'uint32', 0],
            Name        => [1, 'string', undef],
            Type        => [0, 'enum', 'OctetString', [qw(Address DiameterIdentity DiameterURI Enumerated Float32 Float64
                                                          Grouped Integer32 Integer64 IPFilterRule OctetString Time 
                                                          Unsigned32 Unsigned64 UTF8String)]],
        }],
    ],
);


use constant {
    DD_AVPS         => 0,   # hashref, as described in output from _process_yaml_ds_to_avp_pointers
    DD_MSGS         => 1,   # hashref, as described in output from _process_yaml_ds_to_message_pointers
};


# $d = Diameter::Dictionary->new( FromFile => $filepath, FromString => $string );
#
# $d is a blessed listref with elements described above as the DD_* constants.  
# 
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


    # Validate structure of YAML file/string against structure defined above in %element_structre.
    # Also fill in any optional fields that have a default if they aren't present
    $class->_validate_and_expand_yaml_datastructure( $yaml_ds )
        or do {
            $@ = "YAML parse error: $@";
            return undef;
        };


    # Convert serialized YAML datastructure into two hashrefs to facilitate common operations (looking
    # up message and avp structure information)
    my $avp_ptrs_hr = $class->_process_yaml_ds_to_avp_pointers( $yaml_ds )
        or return undef;

    my $msg_ptrs_hr = $class->_process_yaml_ds_to_message_pointers( $yaml_ds, $avp_ptrs_hr )
        or return undef;

    return bless [
        $avp_ptrs_hr,
        $msg_ptrs_hr,
    ], $class;
}


# $m = $d->message( %msg_type, Avps => [ [ $name, $value ], ... ] ) or die $@;
#   $msg_type{ApplicationId} and $msg_type{Code}, optionally $msg_type{IsRequest}
#   $msg_type{Code}, optionally $msg_type{IsRequest}
#   $msg_type{Name}
#
# may include $msg_type{ValidateAvps} (default is true)
#
# undef and set $@ on failure
# $@ will begin with Unknown Message Type Exception if the message type is not
# known in the dictionary.  It will begin with Unknown AVP Type Exception if one
# of the provided AVPs is not in the dictionary.  It will begin with Incorrect AVP Type Value
# if one of the AVPs has a value that is not permitted by type.  It will begin with
# Missing AVP if a mandatory AVP is missing.  It will begin with Illegal AVP if one of the
# AVPs is not permitted for this Message Type based on the dictionary.
#
sub message {
    my $self = shift;
    my %params = @_;

    my $msg_desc;
    if (exists $params{Name} && defined $params{Name}) {
        if (exists $self->[DD_MSGS]->{Name}->{$params{Name}}) {
            $msg_desc = $self->[DD_MSGS]->{Name}->{$params{Name}};
        }
        else {
            return undef;
        }
    }
    elsif (exists $params{Code} && defined $params{Code}) {
        if (!exists $params{ApplicationId}) { $params{ApplicationId} = 0 }
        if (!exists $params{IsRequest})     { $params{IsRequest}     = 1 }

        if (exists $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"}) {
            if ($params{IsRequest}) {
                $msg_desc = $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"}->[0];
            }
            else {
                $msg_desc = $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"}->[1];
            }
        }
        else {
            return undef;
        }
    }
    else {
        return undef;
    }

}


# $avpobj = $d->avp( Name => $name, Value => $typed_value ) or die;
# $avpobj = $d->avp( Code => $code, Value => $typed_value ) or die;
# $avpobj = $d->avp( VendorId => $vendorid, Code => $code, Value => $typed_value ) or die;
#
sub avp {
    my $self = shift;
    my %params = @_;

    my $avp_desc;
    if (exists $params{Name} && defined $params{Name}) {
        if (exists $self->[DD_AVPS]->{Name}->{$params{Name}}) {
            $avp_desc = $self->[DD_AVPS]->{Name}->{$params{Name}};
        }
        else {
            return undef;
        }
    }
    elsif (exists $params{Code} && defined $params{Code}) {
        my $vendorid = (exists $params{VendorId} && defined $params{VendorId} ? $params{VendorId} : 0);

        if (exists $self->[DD_AVPS]->{Code}->{"$vendorid:$params{Code}"}) {
            $avp_desc = $self->[DD_AVPS]->{Code}->{"$vendorid:$params{Code}"};
        }
        else {
            return undef;
        }
    }
    else {
        return undef;
    }

    return Diameter::Dictionary::Message::AVP->new( Name     => $avp_desc->{Name},     Code => $avp_desc->{Code},
                                                    VendorId => $avp_desc->{VendorId}, Data => $params{Value},
                                                    DataType => $avp_desc->{Type} );
}


# \%v = $d->describe_message( Name => $name | Code => $code | (Code => $code, ApplicationId => $appid) );
sub describe_message {
    my $self = shift;
    my %params = @_;

    my $msg_hr;
    if (exists $params{Name} && defined $params{Name}) {
        $msg_hr = $self->[DD_MSGS]->{Name}->{$params{Name}};
    }
    elsif (exists $params{Code} && defined $params{Code}) {
        if (!exists $params{ApplicationId}) {
            $msg_hr = $self->[DD_MSGS]->{Code}->{"0:$params{Code}"};
        }
        else {
            $msg_hr = $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"};
        }
    }
    else {
        return undef;
    }

    if (!defined $msg_hr) {
        return undef;
    }

    return dclone( $msg_hr );
}


# %v = $d->describe_avp( Name => $name | Code => $code | (Code => $code, VendorId => $vendorid) ); 
sub describe_avp {
    my $self = shift;
    my %params = @_;

    my $avp_hr;
    if (exists $params{Name}) {
        $avp_hr = $self->[DD_AVPS]->{Name}->{$params{Name}};

    }
    elsif (exists $params{Code}) {
        if (!exists $params{VendorId}) {
            $avp_hr = $self->[DD_AVPS]->{Code}->{"0:$params{Code}"};
        }
        else {
            $avp_hr = $self->[DD_AVPS]->{Code}->{"$params{VendorId}:$params{Code}"};
        }
    }
    else {
        return undef;
    }

    if (!defined $avp_hr) {
        return undef;
    }

    return dclone( $avp_hr );
}



#
# \%avp_pointers = $class->_process_yaml_ds_to_avp_pointers( $yaml_ds );
#
# Covert the generated datastructure from the YAML file to a hashref indexed by
# {Code} and {Name}.  {Code} is "$vendorid:$code", while {Name} is from the set of
# names for an AVP.  The value is a hashref of {Code}, {Name}, {VendorId}, {Type}.
# The YAML datastructure must have first been validated.
#
sub _process_yaml_ds_to_avp_pointers {
    my $class = shift;
    my $yaml_ds = shift;

    my %avp_pointers;

    if (!exists $yaml_ds->{AvpTypes}) {
        return { Code => {}, Name => {} };
    }

    foreach my $avp_hr (@{ $yaml_ds->{AvpTypes} }) {
        my ($vendor_id, $code) = ($avp_hr->{VendorId}, $avp_hr->{Code});
        $avp_pointers{Code}{"$vendor_id:$code"} = $avp_hr;
        $avp_pointers{Name}{$avp_hr->{Name}} = $avp_hr;
    }

    return \%avp_pointers;
}


sub _get_normalized_avp {
    my $class = shift;
    my ($avp_id, $avp_ds_hr) = @_;

    if ($avp_id eq "AVP") {
        return "AVP";
    }
    elsif ($avp_id =~ /^(\d+)(:(\d+))?$/) {
        if (!defined $2) {
            $avp_id = "0:$avp_id";
        }
        if ($avp_ds_hr->{Code}->{$avp_id}) {
            return $avp_id;
        }
        else {
            return undef;
        }
    }
    else {
        if (exists $avp_ds_hr->{Name}->{$avp_id}) {
            return $avp_ds_hr->{Name}->{$avp_id}->{VendorId} . ":" . $avp_ds_hr->{Name}->{$avp_id}->{Code};
        }
        else {
            return undef;
        }
    }
}


#
# \%message_pointers = $class->_process_yaml_ds_to_message_pointers( $yaml_ds, $avp_ds );
#
# Convert the generated datastructure from the YAML file to a hashref indexed
# by {Code} and {Name}.  {Code} points to a hashref indexed by
# "$application_id:$code" then listref of [$request, $answer], and {Name} is
# indexed by name.  Value is hashref of {AvpOrder}, which is hashref by
# "$vendorid:$code" of Avp order; then {MandatoryAvps}, which is a hashref by
# "$vendorid:$code"; then {OptionalAvps}, which is a hashref by
# "$vendorid:$code", then {Properties}, which is a hashref of {ApplicationId},
# {Codes}, {Name}, {AbbreviatedName}, {Error} and {Proxiable}.  The value for each
# {"$vendorid:$code"} hashref key is the count when used with {MandatoryAvps}
# and {OptionalAvps}.  For {AvpOrder}, the value is simply 1.
#
# If the AVP in the dictionary is "AVP", then no attempt is made to validate a definition,
# since this mean "any AVP".  It is still stored, however, in the definition for the message
# type.
#
# $avp_ds is the datastructure returned by _process_yaml_ds_to_avp_pointers.  If a referenced
# AVP is not defined in that datastructure, set $@ and return undef.
#
sub _process_yaml_ds_to_message_pointers {
    my $class = shift;
    my ($yaml_ds, $avp_ds) = @_;

    my %message_pointers;

    if (!exists $yaml_ds->{MessageTypes}) {
        return { Code => {}, Name => {} };
    }

    foreach my $message_hr (@{ $yaml_ds->{MessageTypes} }) {
        my ($application_id, $code) = ($message_hr->{ApplicationId}, $message_hr->{Code});

        my %properties = (ApplicationId => $application_id,
                          Code          => $code,
                          Error         => $message_hr->{Error},
                          Proxiable     => $message_hr->{Proxiable});

        my %message_ds = (Properties => \%properties);
        my @ra_pair;

        foreach my $s (qw(Request Answer)) {
            my %info = (Properties => \%properties);

            my @normalized_avps;
            foreach my $refd_avp (@{ $message_hr->{$s}->{AvpOrder} }) {
                my $n = $class->_get_normalized_avp( $refd_avp, $avp_ds )
                    or do {
                        $@ = "For ($message_hr->{ApplicationId}:$message_hr->{Code}), $s/AvpOrder contains AVP ($refd_avp) with no corresponding AVP definition";
                        return undef;
                    };

                push @normalized_avps, $n;
            }

            $info{AvpOrder} = \@normalized_avps;

            foreach my $t (qw(MandatoryAvps OptionalAvps)) {
                my %normalized_avps;

                foreach my $avp_def (@{ $message_hr->{$s}->{$t} }) {
                    my ($refd_avp, $count) = split /:/, $avp_def;

                    if (!defined $count) {
                        $count = 1;
                    }
                    elsif ($count ne "*" && $count ne "1*" && $count ne "1") {
                        $@ = "For ($message_hr->{ApplicationId}:$message_hr->{Code}), $s/$t/$refd_avp count ($count) not understood";
                        return undef;
                    }

                    my $n = $class->_get_normalized_avp( $refd_avp, $avp_ds )
                        or do {
                            $@ = "For ($message_hr->{ApplicationId}:$message_hr->{Code}), $s/AvpOrder contains AVP ($refd_avp) with no corresponding AVP definition";
                            return undef;
                        };

                    $normalized_avps{$n} = $count;
                    $info{$t} = \%normalized_avps;
                }
            }

            push @ra_pair, \%info;
        }

        $message_ds{Request}    = $ra_pair[0];
        $message_ds{Answer}     = $ra_pair[1];
        $message_ds{Properties} = \%properties;

        $message_pointers{Code}{"$application_id:$code"} = \%message_ds;

        foreach my $name ($message_hr->{Request}->{Name}, $message_hr->{Request}->{AbbreviatedName}) {
            $message_pointers{Name}{$name} = $ra_pair[0]    if $name ne '';
        }

        foreach my $name ($message_hr->{Answer}->{Name}, $message_hr->{Answer}->{AbbreviatedName}) {
            $message_pointers{Name}{$name} = $ra_pair[1]    if $name ne '';
        }
    }

    return \%message_pointers;
}


#
# $bool = $class->_validate_and_expand_yaml_element( $node_name, $value, \@structure_definition );
#
# Given a YAML element from the datastructure created by YAML::XS, validate it against the package global
# %element_structure.  $node_name is a name for the element node, used in error production if the element
# is not valid.  $value is the value of this element.  @structure_definition is the definition for this
# element in %element_structure.
#
sub _validate_and_expand_yaml_element {
    my $class = shift;
    my ($node_name, $element_value, $structure_def_ar) = @_;

    my ($is_required, $required_type, $default_value, $struct_children) = @{ $structure_def_ar };

    my $element_type = ref $element_value;

    if ($required_type eq "bool") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be YAML boolean";
            return 0;
        }
    }
    elsif ($required_type eq "string") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be a YAML string";
            return 0;
        }

        if (!defined $element_value || $element_value eq "") {
            $@ = "For ($node_name) value cannot be empty";
            return 0;
        }
    }
    elsif ($required_type eq "enum") {
        unless (grep { $element_value eq $_ } @{ $structure_def_ar->[E_CHILDREN] }) {
            $@ = "For ($node_name), value is not in the enum list";
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
    elsif ($required_type eq "list") {
        unless ($element_type eq "ARRAY") {
            $@ = "For ($node_name) value must be a YAML list";
            return 0;
        }
        if (defined $struct_children) {
            for (my $i = 0; $i < @{ $element_value }; $i++) {
                if (!$class->_validate_and_expand_yaml_element( "$node_name/$i", $element_value->[$i], $struct_children )) {
                    return 0;
                }
            }
        }
    }
    elsif ($required_type eq "map") {
        unless ($element_type eq "HASH") {
            $@ = "For ($node_name) value must be a YAML map";
            return 0;
        }

        if (defined $struct_children) {
            my %child_elements = (map { $_ => 1 } (keys %{ $element_value }));

            CHILD_KEY:
            foreach my $struct_child_key (keys %{ $struct_children }) {
                if (!exists $child_elements{$struct_child_key}) {
                    if ($struct_children->{$struct_child_key}->[E_IS_REQUIRED]) {
                        $@ = "For ($node_name) must have child ($struct_child_key)";
                        return 0;
                    }
                    elsif (defined $struct_children->{$struct_child_key}->[E_IS_REQUIRED] && defined $struct_children->{$struct_child_key}->[E_DEFAULT_VALUE]) {
                        $element_value->{$struct_child_key} = $struct_children->{$struct_child_key}->[E_DEFAULT_VALUE];
                        next CHILD_KEY;
                    }
                    else {
                        next CHILD_KEY;
                    }
                }

                if (!$class->_validate_and_expand_yaml_element( "$node_name/$struct_child_key", $element_value->{$struct_child_key}, $struct_children->{$struct_child_key} )) {
                    return 0;
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


# I am preserving this bit of code because I may re-introduce it later.  I don't
# currently think that it is sensible to specify the allowed contained AVPs in
# a Grouped AVP -- or rather, that should be a function of MessageType validation --
# but I'm leaving it here in case I re-decide later.
sub _validate_childavps_element {
    my $class = shift;
    my ($node_name, $element_type, $element_value) = @_;

    unless ($element_type eq "ARRAY") {
        $@ = "For ($node_name) value must be a YAML list";
        return 0;
    }

    for (my $i = 0; $i < @{ $element_value }; $i++) {
        my $nv = $element_value->[$i];
        unless (defined $nv && ref $nv eq 'HASH') {
            $@ = "For ($node_name/$i) value must be a YAML map";
            return 0;
        }

        # must have VendorId+Code, Code or Name
        if (exists $nv->{Code} && defined $nv->{Code} && $nv->{Code} ne "") {
            unless ($nv->{Code} =~ /^\d+$/) {
                $@ = "For ($node_name/$i) Code must be a positive integer";
                return 0;
            }
            if (exists $nv->{Name}) {
                $@ = "For ($node_name/$i) cannot have Code and Name together";
                return 0;
            }

            if (exists $nv->{VendorId} && !defined $nv->{VendorId} && $nv->{VendorId} ne "") {
                unless ($nv->{VendorId} =~ /^\d+$/) {
                    $@ = "For ($node_name/$i) VendorId must be a positive integer";
                    return 0;
                }
            }
            else {
                $nv->{VendorId} = 0;
            }
        }
        elsif (!exist $nv->{Name} || !defined $nv->{Name} || $nv->{Name} eq "") {
            $@ = "For ($node_name/$i) VendorId+Code, Code, or Name must be defined";
            return 0;
        }
        elsif (exists $nv->{VendorId}) {
            $@ = "For ($node_name/$i) cannot specify VendorId with Name";
            return 0;
        }

        if (!exists $nv->{Count} || !defined $nv->{Count} || $nv->{Count} eq "") {
            $nv->{Count} = '*';
        }
        elsif ($nv->{Count} ne "*" && $nv->{Count} !~ /^\d+\*?$/) {
            $@ = "For ($node_name/$i) Count must be *, a positive integer, or a positive integer followed by *";
            return 0;
        }
    }

    return 1;
}


#
# $bool = $class->_validate_and_expand_yaml_datastructure( $yaml_serialized_ds );
#
# Given $yaml_serialized_ds -- the output from YAML::XS -- validate that it conforms
# to the definitions in the global %element_structure.  Also, for any optional element
# with a defined default value, if the element is absent in $yaml_serialized_ds, add
# it with the given default
#
sub _validate_and_expand_yaml_datastructure {
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
        if (!defined $yaml_ds->{MessageTypes}) {
            $yaml_ds->{MessageTypes} = [];
            $struct_ok = 1;
        }
        elsif (ref $yaml_ds->{MessageTypes} ne "ARRAY") {
            $@ = "For (MessageTypes), type must be YAML list";
            return 0;
        }
        else {
            $struct_ok = $class->_validate_and_expand_yaml_element( "MessageTypes", $yaml_ds->{MessageTypes}, $element_structure{MessageTypes} );
        }
    }

    if (exists $yaml_ds->{AvpTypes}) {
        if (!defined $yaml_ds->{AvpTypes}) {
            $yaml_ds->{AvpTypes} = [];
            $struct_ok = 1;
        }
        elsif (ref $yaml_ds->{AvpTypes} ne "ARRAY") {
            $@ = "For (AvpTypes), type must be YAML list";
            return 0;
        }
        else {
            $struct_ok = $class->_validate_and_expand_yaml_element( "AvpTypes", $yaml_ds->{AvpTypes}, $element_structure{AvpTypes} );
        }
    }

    return $struct_ok;
}



package Diameter::Dictionary::Message::AVP;

use warnings;

use parent 'Diameter::Message::AVP';

no strict;
use constant {
    AVP_NAME            => Diameter::Message::AVP::AVP__LAST_ELEMENT + 1,
};

use strict;


# Because we know that Diameter::Message::AVP is a blessed listref,
# we extend the listref here, but this means that, if the Diameter::Message::AVP
# listref is changed, it must be changed here, too
#
sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new( %params );

    bless $self, $class;

    $self->[AVP_NAME] = $params{Name};

    return $self;
}


sub name {
    return shift->[AVP_NAME];
}


package Diameter::Dictionary::Message;

use warnings;

use parent 'Diameter::Message';

no strict;
use constant {
    MESSAGE_NAMES       => Diameter::Message::LAST_ELEMENT + 1,  
};


sub new {

}


sub name {

}


sub aliases {

}



1;
