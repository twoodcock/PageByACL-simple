package PageByACL;
use Dancer2;
use PageByACL::Data
    db => {
        driver => 'sqlite',
        database => 'data/PageByACL-test.sqlite3.db',
    }
    tables => {
        acl => 'test_acl',
        user_roles => 'test_user_roles',
    };

our $VERSION = '0.1';

# for demonstrative purposes, use /u/:userid/route/to/file to access a given
# file "logged in" as the given user.
any "/u/:userid/*" => sub {
    my $route = splat;
    # set the userid
    request->env->{REMOTE_USER} = params->{userid};
    # change the route to the given route.
    forward("/$route");
};

any "/" => \&_dispatch;
any "/*" => \&_dispatch;
sub _dispatch {
    my $dispatch = request->dispatch_path;
    my $remoteUser = request->env->{REMOTE_USER} || 'public';
    my $dir = config->{public_dir};
    if (!-e "$dir/$dispatch") {
        # If the file doesn't exist, we return a 404.
        status "not_found";
        return "$dispatch was not found";
    }
    if (_path_allowed(userid=>$remoteUser, path=>$dispatch)) {
        # If the file does exist and we are granted access, we simply deliver
        # the file.
        send_file($dispatch);
    }
    # We are not allowed to access this file.
    status 403;
    return "permission denied";
}

sub _path_allowed {
    my ($class, %params) = @_;
    my ($path) = PageByACL::Data->acl->search_files_by_user(
        $params{userid}, 
        $params{path},
    );
    return $path;
}

1; 

__END__

=head1 NAME

pagebyacl - app to render a static, but access controlled web site.

=head1 DESCRIPTION

This app is too stupid to be of real use. It exsists for demonstration of its
various components.

This app provides access controlled access to a set of web pages with public
access to a more general set of pages. All pages are files on the file system.
A database specifies which files are accessible.

We assume the user has been logged in, if they wish to be, via a middleware
component that offers us REMOTE_USER in the environment.

=cut
