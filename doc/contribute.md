# Contributing

Daylight: the intial release.  We encourage you to contribute, explore
our new framework, to seek out strange new bugs and build new possiblities,
to boldly go where we have not gone before.

## History

Daylight was built as an API for a web application on the AT&T Cloud team
using the domain model needed for several tasks in the organization.  We
wanted to be able to lift sections of our codebase out of the monolithic
codebase with little-to-no code changes between `ActiveRecord` and
`ActiveResource`.

The functionality was built for the organization's usecases and while
documenting, we've noticed "holes" or possiblities within the codebase.

Daylight is the extracted files that sat between our API models and the
Rails components.  We've also extracted some of our tools such as the
mocking framework we built and Documentation Rails engine with hopes
that they might serve useful to API developers.

Daylight is named as such for our intent the framework would be able to
"_see the light of day_".

## Reporting an Issue

We are using Github's [Issues](https://github.com/att-cloud/daylight/issues)
to track all future work and bugs.  Please investigate if there is a bug
already submitted for your the issue you've found and if not, submit a
[new issue](https://github.com/att-cloud/daylight/issues/new).

Include a title and a clear statement of a problem.  If you can, add the
steps to reproduce, a backtrace, the Daylight gem version as well as the
Rails & ActiveModelSerializer version numbers.  Please include example
code when possible.

## Contributing to the Codebase

Daylight is a self-contained, running rspec tests against a _dummy_ Rails
application backed by a sqlite database.  Once you have your
[build Environment](environment.md) up and running, you will be able to
run the tests.

Clone (or fork) the Daylight repository:

    $ git clone git://github.com/att-cloud/daylight.git

Switch to your own branch:

    $ cd daylight
    $ git checkout -b my_branch

Build your code and tests.  Ensure they all run, see if you a missing any
tests:

    $ cd daylight
    $ rake spec
    $ rake rcov

Commit your changes:

    $ git commit -a

Issue a [pull request](#https://help.github.com/articles/using-pull-requests)
using your branch with your code changes.

## Understanding

To better understand how a framework extends or alters the underlying Rails
technology.  Here are some additional details on how `Daylight` was built.

Please rely on the following for reference or feel free to ask or suggest:

* [Guiding Principles](principles.md)
* [Build Environment](environment.md)
* [Framework Overview](framework.md)
* [Daylight Benchmarks](benchmarks.md)
