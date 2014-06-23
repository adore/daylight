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
"see the light of day".

## Understanding

To better understand how a framework extends or alters the underlying Rails
technology.  Here are some additional details on how `Daylight` was built:

* [Guiding Principles](principles.md)
* [Build Environment](environment.md)
* [Framework Overview](framework.md)
* [Daylight Benchmarks](benchmarks.md)
