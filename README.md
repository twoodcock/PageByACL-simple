# PageByACL-simple

PageByACL-simple is a prototype project that implements access control for a
static web site.

1.  Use a database (sqlite3) to control access to files.
2.  Assume a document is public if there is no access
    control defined.
3.  Assume login is handled by a Plack::Middleware module before the app is
    invoked by the PSGI app. The app currently expects env->{REMOTE_USER} to be
    set.

# Configuration

This is a Dancer2 app. The main configuration file is config.yml - that is
unchanged from the default. You'll find the environment specific database
configuration in the environments/development.yml file, or in
environments/production.yml for a production release. (This prototype has an
un-edited environments/production.yml.)

# Data Implementation

The data implementation is based around a central data hub class:
PageByACL::Data. This class has a method for each structure the app needs. Data
is accessed by the app through the data hub.

The app configures the data hub, for example, with an sqlite database. The hub
delegates requests for accessors to the appropriate class.

eg:

<pre>
$list = PageByACL::Data\-&gt;acl\-\&gt;find(path=>"/private/file.html");
</pre>

# TODO

1.  Use Template::Toolkit to render nicer failure conditions.
    (404, 403).
2.  Refactor the implementation to make it cleaner.
3.  Document what you've learned.
4.  Publish on github for reference.
5.  Remember this is a prototype project looking for a purpose.
    Go learn something else.

# License

There is no license for this project beyond what is granted implicitly by
publishing on github. This is a prototype for peer review only. It is not
considered mature enough to be the foundation for any public code.
