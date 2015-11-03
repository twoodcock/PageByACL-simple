package PageByACL::Data::CDBI::ACL;
use strict;
use warnings;
use base 'PageByACL::Data::CDBI::Base';

__PACKAGE__->columns('Primary' => 'rowid');
__PACKAGE__->columns('Others' => qw(path role));

sub new {
    die "use add(path=>\$path, role=>\$role)";
}

sub add {
    my ($class, %params) = @_;
    my $roles = $params{roles} || [$params{role}] || [];
    my $count = 0;
    for my $role (@$roles) {
        $class->create({ role => $role, path => $params{path}, });
        $count++;
    }
    return $count;
}

sub find {
    my ($class, %params) = @_;
    my %args;
    $args{path} = $params{path} if (exists $params{path});
    $args{role} = $params{role} if (exists $params{role});
    if (!scalar(keys(%params))) {
        die "invalid find request; pass role or path.";
    }
    return $class->search(%args);
}

sub has_perm {
    my ($class, %params) = @_;
    # if we find an object for the given userid + path, return true
    # otherwise, return false.
    # This is simplistic? Every file has to have roles set.
    my $o = $class->search_files_by_user(%params);
    return $o?1:0;
}

sub search_files_by_user {
    my ($class, %params) = @_;
    # Use Class::DBI's (Ima::DBI's) set_sql method to set up the search,
    # but do it lazliy so  we only do it if necessary.
    if (!$class->can('search_real_files_by_user')) {
        my $user_roles_table = PageByACL::Data->user_roles->table;
        $class->set_sql(
            "real_files_by_user",
            "SELECT path\n"
           ." FROM $user_roles_table ur, __TABLE__ a\n"
           ."WHERE userid=?\n"
           ."  AND (ur.role=a.role)\n"
           ."  AND path=?"
        );
    }
    return $class->search_real_files_by_user($params{userid}, $params{path});
}

1;

__END__

=head1 NAME

PageByACL::Data::CDBI::ACL - access control list based on user roles

=head1 SYNOPSIS

    $count = $class->add(path=>$path, role=>$role);
    $count = $class->add(path=>$path, roles=>[$role1, $role2]);

    $iterator = $class->find(path=>$path);
    @list = $class->find(path=>$path);

    $iterator = $class->find(role=>$role);
    @list = $class->find(role=>$role);

    $iterator = $class->search_files_by_user($userid, $path);
    @list = $class->search_files_by_user($userid, $path);

    # standard Class::DBI style interface
    $o = $class->create({path=>$path, role=>$role});

    $int = $o->rowid;
    $string = $o->role;
    $string = $o->path;

=head1 DESCRIPTION

This class provides an interface to the set of user roles allowed to access
a given file. It provides a search function to determine whether a given
path is accessible to the given user.

=head1 INTERFACE

=head2 add(path=>$path, role=>$role or roles=>\@roles)

Set ACL values for the given path.

Think of this as "add routes that do not already exist". This will die if
routes exist.

This method does not return any values.

=head2 find(path=>$path or role=>$role)

Locate all objects for the given path or role. Returns a list in array
context or an iterator in scalar context.

=head2 has_perm(path=>$path, userid=>$userid)

Returns a boolean, true if the given userid's role set matches one of the
roles allowed to access the path.

=head3 BUGS: 

Paths are specific and exact. This means "/path/to/dir/" might have a
different setting than "/path/to/dir/index.html"

=head2 search_files_by_user($user, $path)

Returns an ACL object if the given user has a role that is allowed access to
the given path.

=head2 BUGS

This is simpliestic? UNIX permissions are inherited. The current
implementation requires permission to be set on the exact path.

=head2 Class::DBI

This class offers the normal Class::DBI API. You should use other interface
methods so your code does not depend on the Class::DBI API.

=cut
