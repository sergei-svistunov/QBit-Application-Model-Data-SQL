package QBit::Application::Model::Data::SQL;

use qbit;

use base qw(QBit::Application::Model::Data);

__PACKAGE__->model_accessors(db => 'QBit::Application::Model::DB');

sub import {
    my ($package, @opts) = @_;

    $package->SUPER::import(@opts);

    my $virtual_class_name = '_::VirtualModelDataSQL::DB::' . $package;
    my %fields             = $package->_fields_();
    my @db_fields;
    my %internal_keys = map {$_ => TRUE} qw(default);
    my @pk            = $package->_pk_();
    my %pk            = map {$_ => TRUE} @pk;

    foreach my $field_name (@pk, sort grep {!exists($pk{$_})} keys(%fields)) {
        my $field_class = $fields{$field_name}->{'type'};
        $field_class = 'Self' unless defined($field_class);
        $field_class = $package->_get_fields_namespace() . "::$field_class";

        require_class($field_class);
        next unless $field_class->isa('QBit::Application::Model::Data::SQL::_::Field::Self');
        push(
            @db_fields,
            {
                (
                    map {$_ => $fields{$field_name}->{$_}}
                      grep {!exists($internal_keys{$_})} keys(%{$fields{$field_name}})
                ),
                name => $field_name
            }
        );
    }

    my $table_meta = {
        $package->_table_name_() => {
            fields => \@db_fields,
            (@pk ? (primary_key => \@pk) : ()),
            ($package->can('_sql_indexes_') ? (indexes => [$package->_sql_indexes_()]) : ()),
        }
    };

    eval(
        "package $virtual_class_name;
    use qbit;
    use base qw(QBit::Application::Model::DB);
    __PACKAGE__->meta(
        tables => \$table_meta
    );
    1;"
    );
    throw $@ if $@;

    my $app_pkg = caller();

    my $app_pkg_stash = package_stash($app_pkg);
    my $db_ISA        = eval('\@' . $app_pkg_stash->{'__MODELS__'}{'db'} . '::ISA');
    push(@$db_ISA, $virtual_class_name);
}

sub _table_name_ {
    my ($package) = @_;

    $package = lc($package);
    $package =~ s/^.+?::model:://;
    $package =~ s/::/_/g;

    return $package;
}

TRUE;
