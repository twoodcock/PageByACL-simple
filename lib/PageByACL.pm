package PageByACL;
use Dancer2;
use PageByACL::Data;

# By default, Dancer2 automatically renders all files in the
# config->{public_dir}. We do not want this.
set static_handler => 0;

BEGIN {
    PageByACL::Data->configure(%{ config->{database} });
}

our $VERSION = '0.1';

# for demonstrative purposes, use /u/:userid/route/to/file to access a given
# file "logged in" as the given user.
any "/u/:userid/*" => sub {
    my ($route) = splat;
    # set the userid
    request->env->{REMOTE_USER} = params->{userid};
    # change the route to the given route.
    forward("/$route");
};

any "/" => \&_dispatch;
any "/*" => \&_dispatch;
sub _dispatch {
    my $dispatch = request->dispatch_path;
    my $remote_user = request->env->{REMOTE_USER};
    if (!$remote_user) {
        $remote_user = 'public';
    }
    header 'X-PageByACL-User' => $remote_user;
    header 'X-PageByACL-Dispatch' => $dispatch;
    my $dir = config->{public_dir};
    if (!-e "$dir/$dispatch") {
        # If the file doesn't exist, we return a 404.
        status "not_found";
        return "$dispatch was not found";
    }
    if (my $perm = _path_allowed(userid=>$remote_user, path=>$dispatch)) {
        header 'X-PageByACL-Perm' => $perm;
        send_file($dispatch);
    }
    # We are not allowed to access this file.
    status 403;
    # This is "a bit" abrupt. IRL you'd want something nicer.
    return "permission denied";
}

sub _path_allowed {
    my (%params) = @_;
    my $iter = PageByACL::Data::acl->find(path=>$params{path});
    if ($iter->count) {
        # If a path is access controled, it will have an entry in the acl
        # table, if not, it is public, and therefore allowed.
        my ($path) = PageByACL::Data->acl->has_perm(
            userid => $params{userid},
            path => $params{path},
        );
        return $path?'private':undef;
    }
    return 'public';
}

1; 

__END__

=head1 NAME

pagebyacl - app to render a static, but access controlled web site.

=head1 DESCRIPTION

This (partial) app provides controlled access to a set of static files on a
web server. The app decides whether the visitor has access based on entries
in a database. If the database does not include access control for a given
file, it is assumed to be public, and is sent.

A PSGI app using this module would need a Plack middleware component to
handle login.

Files are stored on the file system in the 'public' directory. They are only
rendered if and when the web server decides they can be accessed by the
current login session.

The app uses a user-role system. A user may be given a set of roles that
offer access to different sets of files. There are 2 tables required:
- an acl (access control list) table
- a user_roles table offering a list of roles by userid.

=cut
