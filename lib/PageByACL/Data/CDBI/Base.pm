package PageByACL::Data::CDBI::Base;
use base 'Class::DBI';

our $conf;
sub import { shift->configure(@_); }
sub configure {
    my ($class, %params) = @_;
    if (scalar(@_) > 1) {
        $conf = PageByACL::Data::DbConf->new(\%params);
        $class->set_db(
            'Main',
            $conf->dsn,
            $conf->username,
            $conf->password,
            $conf->attr
        );
    }
}

# update or create records
sub set_record_as {
    my ($class, %params) = @_;
    $params{findkey} ||= 'rowid';
    my ($obj) = $class->search($params{findkey} => $params{$params{findkey}});
    if ($obj) {
        for my $key ($class->columns()) {
            if (exists $params{$key} && $key ne 'rowid') {
                $obj->$key($params{$key});
            }
        }
        $obj->update();
    } else {
        my %cr;
        for my $key ($class->columns()) {
            if (exists $params{$key}) {
                $cr{$key} = $params{$key};
            }
        }
        my $ref = \%cr;
        $obj = $class->insert(\%cr);
    }
    return $obj;
}

1;

__END__

=head1 NAME

PageByACL::Data::CDBI::Base - base class for Class::DBI table access modules.

=head1 SYNOPSIS

    use base 'PageByACL::Data::CDBI::Base' %params;

    # or

    PageByACL::Data::CDBI::Base->configure(\%params);

    class->set_record_as(findkey=>'field', %update_or_create_with_these_fields);


=head1 DESCRIPTION

This module configures the database for use by Class::DBI and is used as a
common superclass for Class::DBI table accessors.

=head1 INTERFACE

=head2 class->configure($hashref)

Configure the database by passing the following:

=over

=item driver: the driver name - only mysql or sqlite for now.

=item database: the database name (the file name for sqlite)

=item host: the database host name (optional)

=item port: the database port number (optional)

=item username: the database username (optional)

=item password: the database password (optional)

=item attr: the DBI additional configuration attributes  (optional)

=back

The same parameters can be passed on the 'use' line:

    use PageByACL::Data::CDBI::Base driver=>'sqlite', database=>'/dir/file.db';

=head2 class->set_record_as(findkey=>$key, %params)

This helper method tries to find a record and updates the given parameters if
it is found. If multiple records are found, only the first is updated. If no
record is found, the method tries to create a new record.

returns the Class::DBI object.

Class::DBI has a find_or_create method. I've found find_or_create to be
unreliable...  maybe I should find out why instead of re-rolling it?

=cut
