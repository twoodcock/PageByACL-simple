package PageByACL::Data::DbConf;
use Moo;

sub BUILDARGS {
    my ($class, $conf) = @_;
    for my $key (keys %$conf) {
        if ($key !~ m/^(driver|database|host|port|username|password|attr)$/) {
            delete $conf->{$key}
        }
    }
    return $conf;
}

has driver => ( is=>'ro', required=>1 );
has database => ( is=>'ro', required=>1 );
has host => ( is=>'ro' );
has port => ( is=>'ro' );
has username => ( is=>'ro' );
has password => ( is=>'ro' );
has attr => ( is=>'ro' );

sub dsn {
    my ($class) = @_;
    my $dsn;
    my $database = $class->db;
    if (!$database->{driver}) {
        return undef;
    } elsif ($database->{driver} =~ m/mysql/i) {
        my @drdsn = ("database=$$database{database}");
        for my $key (qw(host port)) {
            push @drdsn, "$key=$$database{$key}" if ($database->{$key});
        }
        $dsn = "DBI:mysql:".join(';', @drdsn);
    } elsif ($database->{driver} =~ m/sqlite/i) {
        if (!-e $database->{database}) {
            die "The database file does not exist ($$database{database}).";
        }
        $dsn = "DBI:SQLite:dbname=$$database{database}";
    }
    return $dsn;
}

1;

__END__

=head1 NAME

PageByACL::Data::DbConf - database configuration class

=head1 SYNOPSIS

    use PageByACL::Data::DbConf;

    $conf = PageByACL::Data::DbConf->new({
        driver=>'sqlite',
        name=>'/path/to/sqlite.db'
    });

    $conf = PageByACL::Data::DbConf->new({
        driver=>'mysql',
        name=>'dbname',
        username=>'dbuser',
        password=>'dbpwd',
    });

    DBI->connect(
        $conf->dsn,
        $conf->username,
        $conf->password,
        $conf->attr,
    );

=head1 DESCRIPTION

This class holds a database configuration.

=head1 INTERFACE

=head2 class->new($hashref)

Create a new configuration object. Pass in the parameters as a hash
reference. Unrecognized parameters are disgarded.

Values are accepted for driver, host, port, database (the database name),
username, password and attr. See the accessor functions for a description of
each.

The driver and database parameters are required. This method will die if these
are not specfied on instantiation.

=head2 obj->dsn

Get the DSN for the database connection. This short cut calculate the DSN
for mysql and sqlite databases. For any other driver, it will return undef.

=head2 obj->driver

Get the database driver. (sqlite or mysql).

=head2 obj->host

Get the database host.

=head2 obj->port

Get the database port.

=head2 obj->database

Get the database database.

=head2 obj->username

Get the database username.

=head2 obj->password

Get the database password.

=head2 obj->attr

Get the attributes (the hash used for configuring extra DBI parameters).
See DBI documentation for details.

=cut
