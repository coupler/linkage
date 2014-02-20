# Linkage

Linkage is a Ruby library for record linkage between one or two database tables.

## What is record linkage?

In an ideal world, records that reference the same entity can be easily
identified. Unfortunately, this isn't always the case. Sometimes there are no
good identifiers in the datasets that you're interested in (ID, social security
number, etc). In such cases, it is necessary to use other means to determine
which records refer to which entity, and this process is known as **record
linkage**.

## Prerequisites

In order to use Linkage, the records you want to link must be in a database.
Linkage has the ability to perform record linkage across different kinds of
databases, so it's okay if your records are not all in the same place.

Since Linkage uses [Sequel](http://sequel.jeremyevans.net/) to communicate with
databases, any database that Sequel supports will work. See [Connecting to a
database](http://sequel.jeremyevans.net/documentation.html) on the Sequel
website for more information about what databases are supported.

## Usage

To perform a record linkage, Linkage needs information about the following:
datasets, result set, and comparators. A dataset refers to a table in a
database. A result set is a place to put score and match information that
Linkage generates.  Comparators describe how records are compared.

A dataset is created via the `Linkage::Dataset` class, along with a connection URI
and a table name:

```ruby
ds = Linkage::Dataset.new('mysql://example.com/database_name', 'table_name')
```

Result sets have different options depending on what storage medium you're
using (CSV or database). For CSVs, you could use:

```ruby
result_set = Linkage::ResultSet['csv'].new('~/my_results')
```

In this case, scores and matches will be saved in CSV files in the `my_results`
directory in your home folder.

To describe a linkage, you can use the `Dataset#link_with` method. This creates
a linkage configuration that you can use to describe how you want the records in
each dataset to be compared. For example:

```ruby
demo = Linkage::Dataset.new('postgres://example.com/foo', 'demographics')
visits = Linkage::Dataset.new('mysql://some-other-host.net/bar', 'visits')
result_set = Linkage::ResultSet['csv'].new('~/my_results')
config = demo.link_with(visits, result_set) do |config|
  config.compare([:first_name, :last_name], [:first_name, :last_name], :equal)
end
```

This linkage would match records from a demographics table to records in a table
with information about doctor visits by using first name and last name.

The `compare` method creates a `Compare` comparator. This is the simplest
comparator in Linkage, and it just compares fields with the operator you specify
(`:equal`, `:less_than`, `:greater_than`, etc). When a comparator compares
two records, it gives the pair of records a score between 0 and 1. In the case
of the example above, records that have the same first name and last name get a
score of 1, and records that don't get a score of 0 (or sometimes, they aren't
scored and assumed to have a score of 0).

Other comparators are `Strcompare` for approximate string matching and
`Within` for matching numbers within a range.

To run a linkage, use a Runner with the resulting configuration from
`Dataset#link_with`:

```ruby
runner = Linkage::Runner.new(config)
runner.execute
```

After running a linkage, there will be a list of matches in a CSV file or
database, depending on how you configured your result set.

The default way linkage determines if two records match is by comparing the
average score to a threshold value (which is 0.5 by default). You can configure
the threshold value like so: `config.threshold = 0.9`.

## Other examples

Linking a dataset to itself:

```ruby
births = Linkage::Dataset.new('postgres://example.com/hospital_data', 'births')
result_set = Linkage::ResultSet['csv'].new('~/my_birth_results')
config = births.link_with(births, result_set) do |config|
  config.compare([:mother_first_name, :mother_last_name], [:mother_first_name, :mother_last_name], :equal)
end
runner = Linkage::Runner.new(config)
runner.execute
```

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

Copyright (c) 2011-2014 Vanderbilt University. See LICENSE.txt for
further details.

