package QBit::Application::Model::Data::SQL::_::Field::ext_model;

use qbit;

use base qw(
  QBit::Application::Model::Data::SQL::_::Field::Generate
  QBit::Application::Model::Data::_::Field::ext_model
  );

sub foreign_keys {
    my ($package, $field_name, $meta) = @_;

    my $app_pkg;
    my $i = 0;
    while ((my @caller = caller(++$i))) {
        if ($caller[0]->isa('QBit::Application')) {
            $app_pkg = $caller[0];
            last;
        }
    }

    my $foreign_model_class = bless({}, $app_pkg)->get_models()->{$meta->{'from'}};
    throw gettext('Unknown model accessor "%s"', $meta->{'from'}) unless defined($foreign_model_class);

    return $foreign_model_class->isa('QBit::Application::Model::Data::SQL')
      ? ([$meta->{'join_fields'}[0] => $foreign_model_class->_table_name_() => $meta->{'join_fields'}[1]])
      : ();
}

TRUE;
