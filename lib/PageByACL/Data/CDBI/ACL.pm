package PageByACL::Data::CDBI::ACL;
use base 'PageByACL::Data::CDBI::Base';

__PACKAGE__->columns('Primary' => 'rowid');
__PACKAGE__->columns('Others' => 'path role');

sub search_files_by_user {
    my ($class, @_) = @_;
    if (!$class->can('search_real_files_by_user')) {
        # lazy pre-compiled search - only set up if needed.
        my $user_roles_table = PageByACL::Data->user_roles->table;
        $class->set_dbi(
            "real_files_by_user",
            "SELECT path\n"
           ." FROM $user_roles_table, __TABLE__\n"
           ."WHERE userid=?\n"
           ."  AND (user_roles.role=acl.role OR acl.role='public')\n"
           ."  AND path=?"
        );
    }
    return $class->search_real_files_by_user(@_);
}

1;
