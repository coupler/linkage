# linkage

Linkage is a library for record linkage between one or two database tables.

## Usage

Linkage uses Sequel to talk to databases, so any database that Sequel can
talk to, Linkage can talk to. You just give Linkage the Sequel-style URI
and the database table name:

    ds = Linkage::Dataset.new('mysql://example.com/database_name', 'table_name')

To describe a linkage, you use the `Dataset#link_with` method.

    parents = Linkage::Dataset.new('postgres://example.com/foo', 'parents')
    children = Linkage::Dataset.new('mysql://some-other-host.net/bar', 'children')
    config = parents.link_with(children) do
      lhs[:first_name].must == rhs[:parent_first_name]
      lhs[:last_name].must == rhs[:parent_last_name]
    end

Note that the datasets don't have to be in the same database, or even on
the same machine.

To run a linkage, use a Runner with the resulting configuration from
`Dataset#link_with`:

    runner = Linkage::SingleThreadedRunner.new(config, 'sqlite://results.db')
    runner.execute

The runner needs a database URI, since it stores its results in two
database tables: `groups` and `groups_records`. The `groups` table contains
all of the unique combinations of values in your datasets, and
`groups_records` maps records to groups.

You can also link a dataset to itself:

    births = Linkage::Dataset.new('postgres://example.com/hospital_data', 'births')
    config = births.link_with(births) do
      lhs[:mother_first_name].must == rhs[:mother_first_name]
      lhs[:mother_last_name].must == rhs[:mother_last_name]
    end
    runner = Linkage::SingleThreadedRunner.new(config, 'sqlite://results.db')
    runner.execute

The above example would find birth records that have mothers with the same
name.

## Contributing to linkage

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.

## Copyright

Copyright (c) 2011 Vanderbilt University. See LICENSE.txt for
further details.

