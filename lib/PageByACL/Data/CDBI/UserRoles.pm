package PageByACL::Data::CDBI::UserRoles;
use base 'PageByACL::Data::CDBI::Base';

__PACKAGE__->columns('Primary' => 'rowid');
__PACKAGE__->columns('Others' => 'userid role');

1;
