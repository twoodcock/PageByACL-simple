#!/usr/bin/perl
use Test::More tests=>6;
use Test::Differences;
use lib qw(. lib);
use strict;
use warnings;

use t::util::load_configuration;

use Plack::Builder;

our $public_dir;
BEGIN {
    $public_dir = 't/data/test_html';
};
use PageByACL with => {
    public_dir => $public_dir,
    logger => 'file',
};
use PageByACL::Data;

use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

# ######
#
# Just like in real life, we have to use middleware before PageByACL (the
# app we are testing) runs to log the user in. We have to set
# $env->{REMOTE_USER} - the variable name the app expects to see in the
# Plack environment hash if a user is logged in.
#
# For the purpose of this test, it suffices to have a global variable
# ($remote_user). The inline middleware below will put the value of the
# variable when the test is run into the Plack environment for the app to
# find.
#
# IRL, you will use a Plack::Middleware module to do this instead.
#
# ######
my $remote_user;
my $app = builder {
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $env->{REMOTE_USER} = $remote_user;
            my $res = $app->($env);
            return $res;
        }
    };
    PageByACL->to_app;
};
is( ref $app, 'CODE', 'The app is a CODE reference; loogs good so far' );

# purge the database's ACLs and roles so we don't have unexpected results
PageByACL::Data->acl->retrieve_all->delete_all;
PageByACL::Data->user_roles->retrieve_all->delete_all;

# make sure the data directory exists.
if (!-d $public_dir) {
    my $rv = mkdir($public_dir);
    if (!$rv) {
        die "Failed to create test dir: $public_dir: $!\n";
    }
}

# Set the public directory in the app's configuration.
#$app->config->{public_dir} = $public_dir;

# Make some files - files have to exist to be accessible. The _mkfile
# routine, locally defined, will also set up roles in the database for us.
_mkfile(path => "/public.html");
_mkfile(path => "/private.html", role=>'private');
_mkfile(path => "/noaccess.html", role=>'noaccess');

# We need a userid.
# test1 will have access to the private.html file, but not noaccess.html.
PageByACL::Data->user_roles->add(userid=>'test1', roles=>['private', 'other']);
# without login, only public files will be available.

my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $placktest = Plack::Test->create($app);

my $request;
my $response;

##### Test set #1: attempt to access files without login. #####
$request = GET "$url/public.html";
$response = $placktest->request($request);

TH("public user, public url",
    $request,
    $response,
    e_status=>200,
    e_headers => {
        'X-PageByACL-User' => 'public',
        'X-PageByACL-Dispatch' => '/public.html',
        'X-PageByACL-Perm' => 'public',
    },
    e_content => "Hello, my name is /public.html. I am public!\n",
);

$request = GET "$url/private.html";
$response = $placktest->request($request);

TH("public user, private url",
    $request,
    $response,
    e_status=>403,
    e_headers => {
        'X-PageByACL-User' => 'public',
        'X-PageByACL-Dispatch' => '/private.html',
    },
    # This is "a bit" abrupt. IRL you'd want something nicer.
    e_content => "permission denied",
);

##### Test set #2: attempt to access files with login. #####
my $userid = 'test1';
# set remote_user to tell the app we built this user is logged in:
$remote_user = $userid;
$request = GET "$url/public.html";
$response = $placktest->request($request);

TH("$userid, public url",
    $request,
    $response,
    e_status=>200,
    e_headers => {
        'X-PageByACL-User' => $userid,
        'X-PageByACL-Dispatch' => '/public.html',
        'X-PageByACL-Perm' => 'public',
    },
    e_content => "Hello, my name is /public.html. I am public!\n",
);

$request = GET "$url/private.html";
$response = $placktest->request($request);

TH("$userid, public url",
    $request,
    $response,
    e_status=>200,
    e_headers => {
        'X-PageByACL-User' => $userid,
        'X-PageByACL-Dispatch' => '/private.html',
        'X-PageByACL-Perm' => 'private',
    },
    e_content => "Hello, my name is /private.html.\nMy role is 'private'.\n",
);

$request = GET "$url/noaccess.html";
$response = $placktest->request($request);

TH("$userid, public url",
    $request,
    $response,
    e_status=>403,
    e_headers => {
        'X-PageByACL-User' => $userid,
        'X-PageByACL-Dispatch' => '/noaccess.html',
    },
    e_content => "permission denied",
);

sub _mkfile {
    my (%params) = @_;
    my $full_path = ">$public_dir/$params{path}";
    my $rv = open(my $F, $full_path);
    if (!$rv) {
        die "failed to create $full_path: $!\n";
    }
    if ($params{role}) {
        PageByACL::Data->acl->add(path=>$params{path}, role=>$params{role});
        print($F "Hello, my name is $params{path}.\nMy role is '$params{role}'.\n");
    } else {
        my $iter = PageByACL::Data->acl->find(path=>$params{path});
        $iter->delete_all;
        print($F "Hello, my name is $params{path}. I am public!\n");
    }
    close($F);
}

# TH($tag, $request, $response, %params)
#
# This function handles basic response testing.
# 1. Check status.
# 2. Check headers, if e_headers is passed.
# 3. Check content.
#
# Uses Test::More's subtest implementation. 1 call to TH is 1 test instance
# in the plan.
#
# Returns true on success, false on failure.
#
sub TH {
    my ($tag, $request, $response, %params) = @_;
    $tag = sprintf('%s [%d] [%s %s] %s', (caller(0))[1,2], $request->method, $request->uri, $tag);
    my $passed = subtest $tag => sub {
        plan tests=>3;

        # status
        ok($response->code == $params{e_status}, 'status check')
        || diag(sprintf("wrong status: %d != %d", $response->code, $params{e_status}));

        # headers
        if (my $h = $params{e_headers}) {
            my $ok = 1;
            for my $header (keys %$h) {
                my $got = $response->header($header);
                my $want = $h->{$header};
                if (!defined($got)) { $got = '[__undef__]' };
                if ($got ne $want) {
                    $ok = 0;
                    diag(sprintf("wrong $header:\n got: %s\nwant: %s", $got, $want));
                }
            }
            ok($ok, "headers check");
        } else {
            ok(1, "headers check (no expected headers)");
        }

        # content (required check, pass e_content.)
        {
            my $content = $response->content();
            table_diff;
            eq_or_diff($content, $params{e_content}, "content check");
        };
    };
    return $passed;
}
