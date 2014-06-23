# Guiding Principles

Here are decisions we made when developing Daylight. We often referred back to these
to help us decide which approach to take. These are not hard-and-fast rules and can
be reviewed and changed as the need arises.

1. Let Rails do all of the database work
   * The client should require the least amount of data to peform the database task
   * Avoid replicating `ActiveRecord` functionality in the client framework
   * Improvements to Rails will benefit the client
   * **Examples**: `through: :associations`, `where_values`, `nested_attributes`

2. Maintain symantic URLs and formatted responses
   * Symantic URLs and query parameters are logically grouped and executed without the client
   * Axiomatically, DSL on the client-side is done through symantic URLs and query parameters
   * Consistency on responses allows the client to _just work_ without adjustment
   * Additions are expressed as additions to the formatted responses
   * **Examples**: associations treated like nested routes, properly named root elements in data, metadata is supported

3. The most granualar objects in responses represent models or their collections
   * Return values only in the context of models (not literals like strings, integers etc.)
   * These objects can be manipulated and saved
   * Rails and `ActiveRecord` don't need to be patched to handle this edgecase
   * **Examples**:associated routes, remote methods

4. Expected behavior of dependent software should not change when extended
   * Developers should not be surprised by unexpected results from software they know and love
   * Exception is to fix bugs or expose problems in the underlying software
   * Changes to the underlying software can be triggered through configuration
   * **Examples**:`AutosaveAssociationFix`, `ActiveResource::Base#has_one`

5. Extend dependent software (gems) by including changes using `ActiveSupport::Concerns`
   * Concerns show in ancestor lists and can chain to original methods via `super`
   * Extensions remain modular and may be extracted individually when needed
   * **Examples**: `read_only`, `where_values` metadata on `Serializer`, `ResourceProxy`, `Refinements`

6. Behavior driven tests drive towards integration testing
   * Use `ActiveRecord` to do the work for retrieving models instead of mocking it out
   * Server responses are a natural place to mock for the client
   * Build models and factories on the fly for the backing test data
   * **Examples**: `Daylight::Mock`, `MigrationHelper`

