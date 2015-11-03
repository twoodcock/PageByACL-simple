package PageByACL::Data::CDBI::UserRoles;
use base 'PageByACL::Data::CDBI::Base';

__PACKAGE__->columns('Primary' => 'rowid');
__PACKAGE__->columns('Others' => qw(userid role));

sub add {
    my ($class, %params) = @_;
    my $roles = $params{roles} || [$params{role}] || [];
    my $count = 0;
    for my $role (@$roles) {
        $class->create({ role => $role, userid => $params{userid}, });
        $count++;
    }
    return $count;
}

sub find {
    my ($class, %params) = @_;
    my %args;
    $args{userid} = $params{userid} if (exists $params{userid});
    $args{role} = $params{role} if (exists $params{role});
    if (!scalar(keys(%params))) {
        die "invalid find request; pass role or userid.";
    }
    return $class->search(%args);
}

1;
