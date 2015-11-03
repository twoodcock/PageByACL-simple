#!/usr/bin/perl
use Test::More tests=>9;
use lib qw(. lib);
use strict;
use warnings;

# load the configuration data (eg database) from the Dancer2 YAML files.
use t::util::load_configuration;

# we have to load the class through PageByACL::Data so the configuration gets
# loaded properly.
use PageByACL::Data;
my $class = PageByACL::Data->acl;

# purge so we don't have unexpected results
$class->retrieve_all->delete_all;
PageByACL::Data->user_roles->retrieve_all->delete_all;

my @l1;
my $o;

my $path_priv1 = '/test/priv1.html';
my $path_priv2 = '/test/priv2.html';
$class->add(path=>$path_priv1, role=>'priv');
$class->add(path=>$path_priv2, role=>'other');
@l1 = $class->find(role=>'priv');
TH_list(
    'search role=priv',
    list=>\@l1,
    e=> [
        { path=>$path_priv1, role=>'priv',}
    ]
);

@l1 = $class->find(path=>$path_priv1);
TH_list(
    "search path=$path_priv1",
    list=>\@l1,
    e=> [
        { path=>$path_priv1, role=>'priv',}
    ]
);

my $path_priv2_1 = '/test/priv2/one.html';
my $path_priv2_2 = '/test/priv2/two.html';
$class->add(path=>$path_priv2_1, roles=>['priv', 'priv2']);
$class->add(path=>$path_priv2_2, roles=>['notpriv', 'priv2']);

@l1 = $class->find(role=>'priv');
TH_list(
    'search role=priv, more paths',
    list=>\@l1,
    e=> [
        { path=>'/test/priv1.html', role=>'priv',},
        { path=>$path_priv2_1, role=>'priv',},
    ]
);

@l1 = $class->find(role=>'priv2');
TH_list(
    'search role=priv2',
    list=>\@l1,
    e=> [
        { path=>$path_priv2_1, role=>'priv2',},
        { path=>$path_priv2_2, role=>'priv2',},
    ]
);

@l1 = $class->find(path=>$path_priv2_1);
TH_list(
    'role search',
    list=>\@l1,
    e=> [
        { path=>$path_priv2_1, role=>'priv',},
        { path=>$path_priv2_1, role=>'priv2',},
    ]
);

# now add a userid that has a role and check permission.
PageByACL::Data->user_roles->add(userid=>'test1', role=>'priv');

my $bool;

$bool = $class->has_perm(path=>$path_priv1, userid=>'test1');
ok($bool, "user test1 has permission to private file (priv1)");

$bool = $class->has_perm(path=>$path_priv2, userid=>'test1');
ok(!$bool, "user test1 does not have permission to private file (priv2)");

# now add priv2 to the roles for userid test1
PageByACL::Data->user_roles->add(userid=>'test1', role=>'priv2');

$bool = $class->has_perm(path=>$path_priv1, userid=>'test1');
ok($bool, "user test1 still has permission to private file (priv1)");

$bool = $class->has_perm(path=>$path_priv2, userid=>'test1');
ok(!$bool, "user test1 now has permission to private file (priv2)");

sub TH_list {
    my ($tag, %params) = @_;
    subtest $tag => sub {
        $tag = sprintf("%s [%d]", $tag, (caller(0))[2]);
        my %seen;
        my @got;
        for my $got (@{$params{list}}) {
            push @got, { path=>$got->path, role=>$got->role };
        }
        is_deeply(\@got, $params{e}, "list of file,role objects");
    }
}


__END__

=head1 NAME

t/Data/acl.t

=head1 DESCRIPTION

This tests the data implementation for a file's access control list (ACL).
The job of this table is to store the user roles that are allowed to access
paths within the system.

We test the find function (a facade for search of questionable value).

=cut
