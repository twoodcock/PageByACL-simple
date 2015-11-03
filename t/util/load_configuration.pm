package t::util::load_configuration;
use YAML;

our $configuration;

BEGIN {
    $configuration = 'environments/development.yml';
    if (!-e $configuration) {
        die __PACKAGE__ . " failed to locate $configuration\n";
    }
    my $config = YAML::LoadFile($configuration);

    require PageByACL::Data;
    PageByACL::Data->configure(%{ $config->{database} });
}

1;

__END__

=head1 NAME

t::util::load_configuration - configuration loader

=head1 SYNOPSIS

    use t::util::load_configuration;

=head1 DESCRIPTION

This module loads configuration data for tests. All you have to do is use
the module.

=cut
