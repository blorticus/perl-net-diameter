package Diameter::Dictionary;

use YAML::XS;
$YAML::XS::LoadBlessed = 0;

use strict;
use warnings;

use FileHandle;


use constant {
    DD_AVPS         => 0,
    DD_MSGS         => 1,
};


# $d = Diameter::Dictionary->new( FromFile => $filepath, FromString => $string );
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

    $class->_validate_and_expand_yaml_datastructure( $yaml_ds )
        or do {
            $@ = "YAML parse error: $@";
            return undef;
        };

    my $avp_ptrs_hr = $class->_process_yaml_ds_to_avp_pointers( $yaml_ds )
        or return undef;

    my $msg_ptrs_hr = $class->_process_yaml_ds_to_message_pointers( $yaml_ds, $avp_ptrs_hr )
        or return undef;

    return bless [
        $avp_ptrs_hr,
        $msg_ptrs_hr,
    ], $class;
}


# $m = $d->message( Name => $name | Code => $code | (Code => $code, ApplicationId => $appid), Avps => [ $d->avp( $name, $value ), ... ] ) or die $@;
sub message {

}

sub avp {

}


# %v = $d->describe_message( Name => $name | Code => $code | (Code => $code, ApplicationId => $appid) );
sub describe_message {
    my $self = shift;
    my %params = @_;

    if (exists $params{Name}) {
        my $msg_hr = $self->[DD_MSGS]->{Name}->{$params{Name}};

        if (!defined $msg_hr) {
            return ();
        }

        return %{ $msg_hr };
    }
    elsif (exists $params{Code}) {
        return ();
    }
    else {
        return ();
    }
}


# %v = $d->describe_avp( Name => $name | Code => $code | (Code => $code, VendorId => $vendorid) ); 
sub describe_avp {

}



#
# \%avp_pointers = $class->_process_yaml_ds_to_avp_pointers( $yaml_ds );
#
# Covert the generated datastructure from the YAML file to a hashref indexed by
# {Code} and {Name}.  {Code} is "$vendorid:$code", while {Name} is from the set of
# names for an AVP.  The value is a hashref of {Code}, {Names}, {VendorId}, {Type}.
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

        foreach my $name (@{ $avp_hr->{Names} }) {
            $avp_pointers{Name}{$name} = $avp_hr;
        }
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
# Convert the generated datastructure from the YAML file to a hashref indexed by
# {Code} and {Name}.  {Code} points to a hashref indexed by "$application_id:$code"
# then listref of [$request, $answer], and {Name} is indexed by name.  Value is hashref of
# {AvpOrder}, which is hashref by "$vendorid:$code" of Avp order; then {MandatoryAvps}, which
# is a hashref by "$vendorid:$code"; then {OptionalAvps}, which is a hashref by
# "$vendorid:$code".  The value for each {"$vendorid:$code"} hashref key is the count when
# used with {MandatoryAvps} and {OptionalAvps}.  For {AvpOrder}, the value is simply 1.
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

        my %message_ds;
        my @ra_pair;

        foreach my $s (qw(Request Answer)) {
            my %avp_description;

            my @normalized_avps;
            foreach my $refd_avp (@{ $message_hr->{$s}->{AvpOrder} }) {
                my $n = $class->_get_normalized_avp( $refd_avp, $avp_ds )
                    or do {
                        $@ = "For ($message_hr->{ApplicationId}:$message_hr->{Code}), $s/AvpOrder contains AVP ($refd_avp) with no corresponding AVP definition";
                        return undef;
                    };

                push @normalized_avps, $n;
            }

            $avp_description{AvpOrder} = \@normalized_avps;

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
                    $avp_description{$t} = \%normalized_avps;
                }
            }

            push @ra_pair, \%avp_description;
        }

        foreach my $ename (qw(ApplicationId Code Proxiable Error)) {
            $message_ds{$ename} = $message_hr->{$ename};
        }

        $message_ds{Request} = $ra_pair[0];
        $message_ds{Answer}  = $ra_pair[1];

        $message_pointers{Code}{"$application_id:$code"} = \%message_ds;

        foreach my $name (@{ $message_hr->{Request}->{Names} }) {
            $message_pointers{Name}{$name} = $ra_pair[0];
        }

        foreach my $name (@{ $message_hr->{Answer}->{Names} }) {
            $message_pointers{Name}{$name} = $ra_pair[1];
        }
    }

    return \%message_pointers;
}


# need to track whether required, what type must be, default value if not present
use constant {
    E_IS_REQUIRED       => 0,
    E_TYPE              => 1,
    E_DEFAULT_VALUE     => 2,
    E_CHILDREN          => 3,
};

my %element_structure = (
    MessageTypes => [0, 'list', [], [1, 'map', {}, {
            ApplicationId => [0, 'uint32', 0],
            Code          => [1, 'uint32', undef],
            Proxiable     => [0, 'bool', 1],
            Error         => [0, 'bool', 0],
            Request       => [0, 'map', {}, {
                Names           => [1, 'list', undef],
                AvpOrder        => [0, 'list', []],
                MandatoryAvps   => [0, 'list', []],
                OptionalAvps    => [0, 'list', []],
            }],
            Answer        => [0, 'map', {}, {
                Names           => [1, 'list', undef],
                AvpOrder        => [0, 'list', []],
                MandatoryAvps   => [0, 'list', []],
                OptionalAvps    => [0, 'list', []],
            }],
        }],
    ],
    AvpTypes => [0, 'list', [], [1, 'map', {}, {
            Code        => [1, 'uint32', undef],
            VendorId    => [0, 'uint32', 0],
            Names       => [1, 'list', undef],
            Type        => [0, 'enum', 'OctetString', [qw(Address DiamIdent DiamURI Enumerated Float32 Float64
                                                          Grouped Integer32 Integer64 OctetString Time 
                                                          Unsigned32 Unsigned64 UTF8String)]],
        }],
    ],
);

sub _validate_and_expand_yaml_element {
    my $class = shift;
    my ($node_name, $element_value, $element_ref, $structure_def_ar) = @_;

    my ($is_required, $required_type, $default_value, $struct_children) = @{ $structure_def_ar };

    if (!$is_required && !defined $element_value) {
        if (!ref $element_value) { $$element_ref = $default_value }
        else                     { $element_value = $default_value }

        return 1;
    }

    my $element_type = ref $element_value;

    if ($required_type eq "bool") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be YAML boolean";
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
                if (!$class->_validate_and_expand_yaml_element( "$node_name/$i",
                                                                $element_value->[$i],
                                                                (ref $element_value->[$i] ? $element_value->[$i] : \$element_value->[$i]),
                                                                $struct_children )) {
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

            foreach my $struct_child_key (keys %{ $struct_children }) {
                if (!exists $child_elements{$struct_child_key}) {
                    if ($struct_children->{$struct_child_key}->[E_IS_REQUIRED]) {
                        $@ = "For ($node_name) must have child ($struct_child_key)";
                        return 0;
                    }
                }

                if (!$class->_validate_and_expand_yaml_element( "$node_name/$struct_child_key",
                                                                $element_value->{$struct_child_key},
                                                                (ref $element_value->{$struct_child_key}
                                                                    ? $element_value->{$struct_child_key} 
                                                                    : \$element_value->{$struct_child_key}),
                                                                $struct_children->{$struct_child_key} )) {
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
            $struct_ok = $class->_validate_and_expand_yaml_element( "MessageTypes", $yaml_ds->{MessageTypes}, $yaml_ds->{MessageTypes}, $element_structure{MessageTypes} );
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
            $struct_ok = $class->_validate_and_expand_yaml_element( "AvpTypes", $yaml_ds->{AvpTypes}, $yaml_ds->{AvpTypes}, $element_structure{AvpTypes} );
        }
    }

    return $struct_ok;
}


1;
