package PageByACL::Data;
use Moo;
use MooX::ClassAttribute;
use PageByACL::Data::CDBI::Base;
use PageByACL::Data::CDBI::ACL;

# set up the source information
# - classes and the database table configuration.
# - table => undef means the table must be configured by the app.
our %sources = (
    user_roles => { class => 'PageByACL::Data::CDBI::UserRoles', table => undef},
    acl   => { class => 'PageByACL::Data::CDBI::ACL',   table => undef},
);

class_has db=> ( is=>'rw', default=>sub{{}});

# The source methods return the class required to provide the app with the data
# it wants. Classes are required lazily - ie only loaded when they are used. In
# addition, database classes make sure their table is configured.
class_has user_roles => ( is=>'lazy', );
    sub _build_user_roles {
        my ($class) = @_;
        my $source_class = $sources{user_roles}->{class};
        if (!$sources{user_roles}->{table}) {
            Carp::croak "The table for the acl data source has not been configured.";
        }
        eval "require $source_class";
        die "$@\n" if $@;
        $source_class->table($sources{user_roles}{table});
        return $source_class;
    }

class_has acl => ( is=>'lazy', );
    sub _build_acl {
        my ($class) = @_;
        my $source_class = $sources{acl}->{class};
        if (!$sources{acl}->{table}) {
            Carp::croak "The table for the acl data source has not been configured.";
        }
        eval "require $source_class";
        die "$@\n" if $@;
        $source_class->table($sources{acl}{table});
        return $source_class;
    }

# Configuration - The user can choose to configure on the 'use' line or after.
# Configuration has 2 hashes: db, the database configuration, tables to set the
# actual tables used.
sub import { shift->configure(@_); }
sub configure {
    my ($class, %params) = @_;
    if ($params{db}) {
        PageByACL::Data::CDBI::Base->configure(%{$params{db}||{}});
    }
    if ($params{tables}) {
        # set the source table for sources that require a table name.
        for my $source (keys %sources) {
            next if (!exists $sources{$source}{table});
            if ($params{tables}{$source}) {
                $sources{$source}{table} = $params{tables}{$source};
            }
        }
    }
}

1;
__END__

=head1 NAME

PageByACL::Data - data hub for the pagebyacl app

=head1 SYNOPSIS

    use PageByACL::Data
        db => {
            database=>dbname,
            driver=>$driver,
            ...,
        },
        tables => {
            users => 'userstable',
            acl => 'acltable',
        }

    # or

    PageByACL::Data->configure(
        db => {
            database=>dbname,
            driver=>$driver,
            ...
        },
        tables => {
            users => 'userstable',
            acl => 'acltable',
        }
    )

    $acl_class = PageByACL::Data->acl;
    $user_class = PageByACL::Data->users;
    $files_class = PageByACL::Data->files;

    # or (for example)

    PageByACL::Data->files->new(params);


=head1 DESCRIPTION

This module provides a data hub; decoupled access to data interfaces. It
makes sure the databases is connected, and lazily loads classes, allowing the
app to get on with its business.

=head1 DATA SOURCES

Data sources are loaded lazily. The code will run 'require My::Module' the
first time a data source is used. This is done using Moo's lazy instantiation.

Data source methods are hard coded, and therefore not, strictly speaking,
plugins.

=head2 users

The users data source provides information about users in the system. This
source is backed by the users table in the database.

=head2 files

The files data source provides information about files in the system. It does
not have a database back end. It knows how to translate a route to a filesystem
path.

=head2 acl

The acl data source provides access to the access control list for a given
file. It has knowledge of both users and files, and is backed by database
storage.

=head1 INTERFACE

=head2 configure(%params)

Configure data storage. For this instance, we have a database. (This is called
on import, so you can pass data this on the 'use' line too.)

=over

=item Warning:

The implementation uses Class::DBI. You can configure the database,
then reconfigure it. Class::DBI delays the connection until it is needed.
However, if you use the database then try to configure another database, you
may get unexpected results.

=back

=over

=item db

A hash containing database configuration with the following keys:

=over

=item database: The database name (the full file path for sqlite)

=item driver: The database driver (mysql or sqlite)

=item username: The database username (mysql)

=item password : The database password  (mysql)

=item host : The database host  (mysql)

=item port : The database port  (mysql)

=item attr : The DBI attribute hash, if needed.

=back

=item tables

A dictionary containing table information for data sources.

Data sources are hard coded into the module. The tables configuration allows
you to specify the table name for a data source. The table name is passed to
the import function of the implementation class.

The table is only accepted for a data source if it is present in the hard coded
%sources hash for the data source. If a table is configurable, it must be
specified.

Tables must be configured by the time the database is initialzied.

Given this:

    %sources = (
        sourcename => { class="My::Class", table=>undef },
    )

The configuration must inclue a table for 'sourcename':

    use PageByACL::Data tables => { sourcename => 'this_table' };

=back

=cut
