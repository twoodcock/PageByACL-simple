requires "Dancer2" => "0.162000";
requires "Class::DBI"               => "0";
requires "Moo"                      => "0";
requires "Moox::ClassAccessor"      => "0";

recommends "YAML"             => "0";
recommends "URL::Encode::XS"  => "0";
recommends "CGI::Deurl::XS"   => "0";
recommends "HTTP::Parser::XS" => "0";

on "test" => sub {
    requires "Test::More"            => "0";
    requires "HTTP::Request::Common" => "0";
};
