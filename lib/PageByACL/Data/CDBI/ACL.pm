package PageByACL::Data::CDBI::ACL;
use base 'PageByACL::Data::CDBI::Base';

__PACKAGE__->columns('Primary' => 'rowid');
__PACKAGE__->columns('Others' => 'path role');

sub search_files_by_user {
    my $class = shift;
    # @_ will be used later.
    if (!$class->can('search_real_files_by_user')) {
        # lazy pre-compiled search - only set up if needed.
        my $user_roles_table = PageByACL::Data->user_roles->table;
        $class->set_sql(
            "real_files_by_user",
            "SELECT path\n"
           ." FROM $user_roles_table ur, __TABLE__ a\n"
           ."WHERE userid=?\n"
           ."  AND (ur.role=a.role OR a.role='public')\n"
           ."  AND path=?"
        );
    }
    return $class->search_real_files_by_user(@_);
}

1;
