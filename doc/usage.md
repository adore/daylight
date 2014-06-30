# Daylight Users Guide

Daylight is extensions built on top of
[ActiveResource](https://github.com/rails/activeresource).
Everything you can do with `ActiveResource` is available to you in Daylight.

Once you have an API [developed](develop.md) with Daylight, you will want to be
able to use it.  As an end-user of an API, it may be distributed to you in a
gem (or other means) and you may not have access to how the API is fulfilled.

Your API developers will either supply documentation or you can look at the
client models.  The client models will describe what functionality is available
to you.  Follow the your API developers instructions on how to setup the API or
refer to the [installation steps](install.md) for options.

#### Table of Contents
* [Client Model Example](#client-model-example)
  * [Namespace and Version](#namespace-and-version)
* [ActiveResource Overview](#activeresource-overview)
* [Refinements](#refinements)
  * [Conditions Additions](#condition-additions)
  * [Order](#order)
  * [Limit and Offset](#limit-and-offset)
  * [Scopes](#scopes)
  * [Chaining](#chaining)
* [Remote Methods](#remote-methods)
* [Associations](#associations)
  * [Nested Resources](#nested-resources)
  * [More Chaining](#more-chaining)
* [Building Objects](#building-objects)
  * [`find_or_create`](#find_or_create)
  * [`find_or_initialize`](#find_or_initialize)
  * [Building using an Association](#building-using-an-associations)
* [Error Handling](#error-handling)
* [Understanding Interaction](#understanding-interaction)
  * [Request Frequency](#request-frequency)
  * [Response Size](#response-size)

## Client Model Example

Imagine you are building a blog, the client models that act as proxy to the
server-side are with which you will be interacting.

As we describe what Daylight can do in addition to `ActiveResource`
refer to these client models in the following `Post` example:

  ````ruby
    class API::V1::Post < Daylight::API
      scope :published, :updated

      belongs_to :blog
      belongs_to :author, class_name: 'api/v1/user'

      has_one :company, through: :blog

      has_many :comments
      has_many :commenters, through: :associated, class_name: 'api/v1/user'

      remote :top_comments, class_name: 'api/v1/comment'
    end
  ````

All of the client models can be interacted with in the
[example application](example.md).

### Namespace and Version

Namespace is the root module for all your client models and can be seen
in this example as the 'API' in the module.  By default, without a supplied
namespace to the `setup!`, the 'API' module will be used.  You can examine
the version:

  ````ruby
    Daylight::API.namespace #=> 'API'
  ````

Daylight client models will be versioned and this can be seen in this example
as the `V1` module.  By default, without a supplied version to the `setup!`,
the most recent version will be selected.  You can examine the version:

  ````ruby
    Daylight::API.version #=> 'V1'
  ````

When you develop using a Daylight API.  You do not need to specify the version
in your constant names as they are _aliased_ to the currently selected version
for your convinience:

  ````ruby
    API::Post  #=> API::V1::Post
  ````

We will use the _aliased_ version of the constant names in the following
examples unless otherwise noted.

---

## ActiveResource Overview

With a `Post` you can use the following `ActiveResource` functionality as
you've become accustomed. Find a `Post` and examine its attributes:


  ````ruby
    post = API::Post.find(1)  #=> #<API::V1::Post:0x007ffa8c4159e0 ..>
    post.title                #=> "100 Best Albums of 2014"
  ````

Get all instances of `Post`, or just the first or last:

  ````ruby
    API::Post.all            #=> [#<API::V1::Post:0x007ffa8d59abe8 ..>,
                             #=>  #<API::V1::Post:0x007ffa8d59a788 ..>, ...]

    API::Post.first          #=> #<API::V1::Post:0x007ffa8d59abe8 ..>
    API::Post.last           #=> #<API::V1::Post:0x007ffa8c4763d0 ..>
  ````

> NOTE: Daylight add a [limit](#limit-and-offset) condition to get the first
> `Post` as an optimization.  There is no optimization for `last` as it is
> equivalent to `Post.all.to_a.last`

You can `create`, `update`, `delete` a `Post`.  Here's an example of an `update`:

  ````ruby
    post = API::Post.find(1)  #=> #<Bluesky::V1::Zone:0x007ffa8c44fde8 ..>
    post.title = "100 Best Albums of All Time"
    post.save                 #=> true
  ````

Get associated resources:

  ````ruby
    post = API::Post.find(1)  #=> #<API::V1::Post:0x007ffa8c44fde8 ..>
    post.comments             #=> [#<API::V1::Comment:0x007ffa8c4843b8 ..>,
                              #    #<API::V1::Comment:0x007ffa8c48e728 ..>, ...]
  ````

Search across the collection of resources:

  ````ruby
    posts = API::Post.where(created_by: 101)
    posts.size             #=> 23
    posts.first.created_by #=> 101
  ````

You can use any multiple conditions:

  ````ruby
    posts = API::Post.where(created_by: 101, blog_id: 1, published: true)
    posts.size             #=> 15
    posts.first.created_by #=> 101
    posts.first.blog_id    #=> 1
    posts.first.published  #=> true
  ````

You can use conditions based on results of other searches:

  ````ruby
    posts = API::Post.where(created_by: API::User.find_by(username: "reidmix"))
    posts.size             #=> 23
    posts.first.created_by #=> 101
  ````

> NOTE: This will issue two requests, the first by `find_by` and the second
> by `where`.

Please refer to the [ActiveResource](https://github.com/rails/activeresource)
documenation for more information.

---

## Refinements

Daylight offers many ways to refine queries across collections.  These include
conditions, scopes, order, offset, and limit.

### Condition Additions

There are several additions to `ActiveResource` conditions.  Which attributes
may be refined need to be documented by your API developer but can be inspected
on a retrieved instance:

  ````ruby
    post = API::Post.find(1)
    post.attributes.keys #=> ["id", "blog_id", "title", "body", "slug",  "published", "published_on", "created_by"]
  ````

If you know there to be one result or only need the first result, use `find_by`:

  ````ruby
    post = API::Post.find_by(slug: "100-best-albums-of-2014")
    posts.slug #=> "100-best-albums-of-2014"
  ````

And `where` clauses may be chained together similarly to `ActiveRecord`:

  ````ruby
    posts = API::Post.where(created_by: 101).where(blog_id: 1).where(published: true)
    posts.size             #=> 15
    posts.first.created_by #=> 101
    posts.first.blog_id    #=> 1
    posts.first.published  #=> true
  ````

In fact there's more to [chaining](#chaining) than just `where` clauses.

### Order

As in `ActiveRecord` you can also refine by `limit`, `offset`, and `order`

  ````ruby
    posts = API::Post.order_by(:published_on)
    posts.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']
  ````

You can also specify the direction or reverse the direction:

  ````ruby
    posts = API::Post.order_by('published_on ASC')
    posts.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']

    posts = API::Post.order_by('published_on DESC')
    posts.map(&:published_on) #=> ['2014-06-26', '2014-06-21', '2014-01-01']
  ````

### Limit and Offset

You can `limit` the results that are returned by the API:

  ````ruby
    posts = API::Post.limit(1)
    posts.size #=> 1

    posts = API::Post.limit(10)
    posts.size #=> 10
  ````

And you can `offset` which resources to be returned:

  ````ruby
    posts = API::Post.all
    posts.map(&:id)  #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    posts = API::Post.offset(5)
    posts.map(&:id)  #=> [6, 7, 8, 9, 10]
  ````

### Scopes

Scopes are conditions made available on the client-side model and executed
server-side.  The function of a scope needs to be documented by your API
developer but which scopes are available be inspected in client model
or find in the instance:

  ````ruby
    API::Post.scope_names #=> [:published, :updated]
  ````

You can call a scope directly on the model class:

  ````ruby
    posts = API::Post.published

    # assuming published scope on the server-side is
    # scope :published, -> {where.not(published_on: nil)}

    posts.first.published_on                  #=> true
    posts.all? {|p| p.published_on.present? } #=> true
  ````

You may call multiple scopes on a model:

  ````ruby
    posts = API::Post.published.edited

    # assuming published scope on the server-side is
    # scope :edited, -> {where.not(edited_on: nil)}

    posts.first.published_on                  #=> true
    posts.first.edited_on                     #=> true

    posts.all? {|p| p.published_on.present? } #=> true
    posts.all? {|p| p.edited_on.present? }    #=> true
  ````

### Chaining

All of the above refinements are as limited to the one being used.  Daylight
allows all or any combination of the refinements to be chained together for
better searches:

  ````ruby
  # NONE: get all posts
  posts = API::Post.all
  posts.map(&:id)          #=> [10, 3, 2, 4, 7, 5, 6, 1, 9, 8]

  # SCOPE: get published posts
  posts = API::Post.published
  posts.map(&:id)          #=> [3, 2, 7, 5, 6, 1, 9, 8]
  posts.first.published_on #=> '2013-09-03'

  # WHERE 1 condition: get posts for blog_id=2
  posts = API::Post.where(blog_id: 2)
  posts.map(&:id)           #=> [2, 5, 1, 9, 8]
  posts.map(&:blog_id)      #=> [2, 2, 2, 2, 2]

  # WHERE 2 conditions: get posts for blog_id=101 AND created_by=2
  posts = API::Post.where(blog_id: 2).where(created_by: 101))
  posts.map(&:id)          #=> [2, 9, 8]
  posts.map(&:created_by)  #=> [101, 101, 101]

  # ORDER: get posts for blog_id=2 AND created_by=101 order by published_on
  posts = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on)
  posts.map(&:id)           #=> [2, 8, 9]
  posts.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']

  # OFFSET: get posts for blog_id=2 AND created_by=101 order by published_on after the first one
  posts = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on).offset(1)
  posts.map(&:id)           #=> [8, 9]

  # LIMIT: get posts for blog_id=2 AND created_by=2 order_by published_on and just the second one
  posts = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on).offset(1).limit(1)
  posts.map(&:id)           #=> [8]

  post = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on).offset(1).limit(1).first
  post.id                   #=> 8
  post.blog_id              #=> 2
  post.created_by           #=> 101
  post.published_on         # '2014-06-21'
  ````

> NOTE: Since `offset` and `limit` can be chained together, you can use these
> with your favorite paginator.

In all of these cases, Daylight issues only one request per search.
See [Request Parameters](develop.md#request-parameters) for further reading.

---

## Associations

Associations work as they do today in `ActiveResource` One one notable
exception.  Client models that have the `has_many through: :associated` will
perform the lookup for associated objects server-side.

> NOTE: This is useful if conditions or configuration is defined on the
> server-side model to perform correctly.  Refer to
> [developing models](develop.md#models) for more information.

Daylight adds additional functionality directly on the association:
* add new resources
* update existing resources
* add a new resource to a collection
* associate two existing resources

Currently, `ActiveResource` will only let you associate a resource by setting
the `foreign_key` directly on a model.

###  Nested Resources

When manipulating resources on an association, we call these _Nested Resources_.

> INFO: We call it "Nested Resource" because data for them are sent
> as a nested hash on the parent resource and server-side employ the
> `accepts_nested_attributes_for` mechanism.

Not all nested resources can be manipulated on the model, you can see which
objects are accepted by inspecting the instance:

  ````
    post = API::Post.find(1)
    post.nested_resources #=> [:author, :comments]
  ````

In this example, posts will reject updates to `blog`, `company`, and
`commenters` nested objects.

To create a new nested object is simple, create the object and set it on the
`has_one` or `has_many` association:

#### Creating a Nested Resource

You can create a new nested resource for a new or existing resources.  For
example a new `post`:

  ````ruby
    post = API::Post.new
    post.title  = "100 Best Albums of 2014"
    post.author = API::User.new(username: 'reidmix')
    post.save       #=> true
    post.id         #=> 43

    # reload the original object to see the new user
    post = API::Post.find(43)
    post.author.id  #=> 101
    post.created_by #=> 101 (foreign_key on post)

    # you can look up the new user directly
    user = API::User.find(101)
    user.username #=> "reidmix"
  ````

This will work on an existing post:

  ````ruby
    post = API::Post.first
    post.author = API::User.new(username: 'dmcinnes')
    post.save       #=> true

    # reload the original object to see the new user
    post = API::Post.first
    post.author.id  #=> 102
    post.created_by #=> 102 (foreign_key on post)

    # you can look up the new user directly
    user = API::User.find(102)
    user.username #=> "dmcinness"
  ````

#### Creating a Nested Resource in a Collection

You can also create a nested object via a collection on a new or existing
resource.  For example, on our new `post`:

  ````ruby
    post = API::Post.new
    post.comments #=> []
    post.comments << API::Comment.new(message: 'First!')
    post.save #=> true

    # reload the original object to see the new comment
    post = API::Post.first
    post.comments.first.id      #=> 321
    post.comments.first.message #=> "First!"

    # you can look up the new comment
    comment = API::Comment.find(321)
    comment.post_id #=> 1
  ````

You can also add a nested object to an existing collection:

  ````ruby
    post = API::Post.first
    post.comments #=> []
    post.comments << API::Comment.new(message: 'Last!')
    post.save #=> true

    # reload the original object to see the new comment
    post = API::Post.first
    post.comments.last.id      #=> 322
    post.comments.last.message #=> "Last!"

    # you can look up the new comment
    comment = API::Comment.find(322)
    comment.post_id #=> 1
  ````

#### Updating a Nested Resource

Updates to nested resources are not saved by saving the parent resource.
You must save the nested resources directly:

  ````ruby
    post = API::Post.first
    post.auhor.full_name = "Reid MacDonald"
    post.auhor.save #=> true

    post = API::Post.first
    post.author.full_name #=> "Reid MacDonald"
  ````

This is the same as saying:

  ````ruby
    post = API::Post.first

    author = post.author
    auhor.full_name = "Reid MacDonald"
    auhor.save #=> true

    post = API::Post.first
    post.author.full_name #=> "Reid MacDonald"
  ````

The same is true of nested objects in collections:

  ````ruby
    post = API::Post.first

    first_comment = post.comments.first
    first_comment.message = "First!"
    first_comment.save #=> true

    post = API::Post.first
    post.comments.first.message #=> "First!"
  ````

> FUTURE [#5](https://github.com/att-cloud/daylight/issues/5):
> Updates to the associated nested resource do not get saved when the parent
> resources are saved and they should be.

#### Associating an Existing Nested Resources

Associating using an existing nested records is possible with Daylight.  The
nested record does not need to be new as they do in `ActiveRecord`.

Setting an existing nested resource on a new or existing parent resource will
associate them:

  ````ruby
    post = API::Post.first

    post.author = API::User.find_by(username: 'reidmix')
    post.save #=> true

    post.created_by #=> 101
    post.author.id  #=> 101
  ````

This also will work to add to a collection on a new or existing resource:

  ````ruby
    post = API::Post.first

    post.commenters << API::User.find_by(username: 'reidmix')
    post.save #=> true

    post = API::Post.first
    post.commenters.find {|c| c.username == 'reidmix'} # #<API::V1::User:0x007fe2cfc45ce8 ..>
  ````

> FUTURE [#15](https://github.com/att-cloud/daylight/issues/15):
> There is no way to remove an nested resource from a collection nor empty the collection.

### More Chaining

Along with the collection returned by queries across collections, you may
continue to apply refinements to associations.

Similar to [chaining](#chainging), refinements on assoications.:

  ````ruby
  # NONE: get all comments for a post
  comments = API::Post.find(1).comments
  comments.map(&:id)          #=> [11, 33, 32, 54, 17, 15, 16, 1, 90, 81]

  # SCOPE: get a post's edited comments
  comments = API::Post.find(1).comments.edited
  comments.map(&:id)          #=> [33, 32, 17, 15, 16, 1, 90, 81]
  comments.first.edited_on    #=> '2013-09-03'

  # WHERE 1 condition: get a post's comments for blog_id=2
  comments = API::Post.find(1).comments.where(has_images: true)
  comments.map(&:id)           #=> [32, 15, 1, 90, 81]
  comments.map(&:has_images)   #=> [true, true, true, true, true]

  # WHERE 2 conditions: get a post's comments that has_images AND created_by=101
  comments = API::Post.find(1).comments.where(has_images: true).where(created_by: 101))
  comments.map(&:id)          #=> [32, 90, 81]
  comments.map(&:created_by)  #=> [101, 101, 101]

  # ORDER: get a post's comments that has_images AND created_by=101 order by edited_on
  comments = API::Post.find(1).where(has_images: true).where(created_by: 101)).order(:edited_on)
  comments.map(&:id)           #=> [32, 81, 90]
  comments.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']

  # OFFSET: get post's comments that has_images AND created_by=101 order by edited_on after the first one
  comments = API::Post.find(1),where(has_images: true).where(created_by: 101)).order(:edited_on).offset(1)
  comments.map(&:id)           #=> [80, 91]

  # LIMIT: get post's comments that has_images AND created_by=101 order by edited_on and just the second one
  comments = API::Post.find(1).where(has_images: true).where(created_by: 101)).order(:edited_on).offset(1).limit(1)
  comments.map(&:id)           #=> [80]

  comments = API::Post.find(1).where(has_images: true).where(created_by: 101)).order(:edited_on).offset(1).limit(1).first
  comments.id                   #=> 80
  comments.has_images           #=> true
  comments.created_by           #=> 101
  comments.published_on         # '2014-06-21'
  ````

As you could guess, you could end up with very sophisticated queries traversing
multiple associations.  For example:

`API::Post.published.updated.find_by(slug: '100-best-albums-of-2014').comments.edited.where(has_images: true).first.images.approved`

Please review [Request Frequency](#request-frequency) to better understand how
the requests are composed.

---

## Building Objects

Most of the time, you want to check to see if an object already exists and if
it doesn't build that object.  `ActiveResource` already supplies this
functionality with `find_or_create` and `find_or_initialze`.

Daylight ensures that these methods work with refinements & chaining and
ensures the requests are properly formatted for the server.

> NOTE: The refinements are expressive but can become very complicated quickly.
> Daylight uses the [where_values](develop.md#where_values) generated by the
> server to build the objects.

### `find_or_create`

The `first_or_create` method will save the object if it does not already exist.

  ````ruby
    post = API::Post.where(slug: '100-best-albums-of-2014').first_or_create
    post.new?   #=> false
    post.exerpt = "Ranked list of the 100 best albums so far in 2014"
    post.save   #=> true
  ````

If there are [validation errors](#handling-errors) the object will be
instantiated but it will not be saved.  You will be able to view the
error messages and see that the object is still new:

  ````ruby
    post = API::Post.where(slug: '100-best-albums-of-2014').first_or_create
    post.new?             #=> true
    post.errors.present?  #=> true
    post.errors.messages  #=> {:base=>[Author must be present]}
  ````

You can use all of Daylight's refinement [chaining](#chaining) to search for a
match:

  ````ruby
    latest_post = API::Post.where(created_by: 101).order(:published_on).first_or_create
    latest_post.new?      #=> false
    latest_post.author.id #=> 101
  ````

### `find_or_intialize`

The `first_or_initialize` will instatiate the object but not save it
automatically.

  ````ruby
    post = API::Post.where(slug: '100-best-albums-of-2014').first_or_initialize({
        exerpt: "Ranked list of the 100 best albums so far in 2014"
      })
    post.new?   #=> true
    post.save   #=> true
  ````

Again, all of the Daylight's refinement chaining can be used.

### Building using an Associations


---

## Remote Methods

Remote methods are any associated record or collection that is available via a
public instance method server-side.  For all intents and purposes, the
differences between a remote method and an associations are:
- Remote methods may return a single record
- Remote methods cannot be chained

> FUTURE [#4](https://github.com/att-cloud/daylight/issues/4)
> Remoted methods may be implemented using the association mechanism.

The function of a remoted method needs to be documented by your API developer
but which remoted methods are available be inspected in client model.

Given the `top_comments` remoted method:

  ````ruby
    API::Post.find(1).top_comments    #=> [#<API::V1::Comment:0x007ffa8c4843b8 ..>,
                                      #    #<API::V1::Comment:0x007ffa8c48e728 ..>, ...]
   ````

As you can see, remote methods cannot be chained:

  ````ruby
    API::Post.find(1).top_comments.find_by(user_id: 1)

    #=> NoMethodError: undefined method `find_by' for #<ActiveResource::Collection:0x007f83208937a8>
   ````

---



## Error Handling

---

## Understanding Interaction

###  Request Frequency

`API::Post.published.updated.find_by(slug: '100-best-albums-of-2014').comments.edited.where(has_images: true).first.images.approved`

`Bluesky::Zone.nonretired.production.find_by(code: 'sql1').tenants.find_by(name: 'nosql-accenture-dev').vms.running`

    GET "/v1/posts.json?filters[slug]=100-best-albums-of-2014&limit=1&scopes[]=published&scopes[]=updated"
    GET "/v1/posts/8/comments.json?filters[has_images]=true&scopes[]=comments"
    GET "/v1/comments/1161/images.json?scopes[]=approved"

From our example on in the [README](../README.doc) we show creating a `Post`
and `User` and associating the two:

    post = API::Post.new(slug: '100-best-albums-2014')
    post.author = API::User.find_or_create(username: 'reidmix')
    post.save

There are 3 queries to the server:

1. To lookup a `User` with the username 'reidmix'
2. The creation of the `User` with the username 'reidmix'
3. Save the `Post` and associate the newly created `User`

### Response Size

