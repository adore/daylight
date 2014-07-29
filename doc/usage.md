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
  * [`first_or_create`](#first_or_create)
  * [`first_or_initialize`](#first_or_initialize)
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

      has_many :comments,   use: 'resource'
      has_many :commenters, class_name: 'api/v1/user'

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
    posts = API::Post.order(:published_on)
    posts.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']
  ````

You can also specify the direction or reverse the direction:

  ````ruby
    posts = API::Post.order('published_on ASC')
    posts.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']

    posts = API::Post.order('published_on DESC')
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
  posts = API::Post.where(blog_id: 2).where(created_by: 101)
  posts.map(&:id)          #=> [2, 9, 8]
  posts.map(&:created_by)  #=> [101, 101, 101]

  # ORDER: get posts for blog_id=2 AND created_by=101 order by published_on
  posts = API::Post.where(blog_id: 2).where(created_by: 101).order(:published_on)
  posts.map(&:id)           #=> [2, 8, 9]
  posts.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']

  # OFFSET: get posts for blog_id=2 AND created_by=101 order by published_on after the first one
  posts = API::Post.where(blog_id: 2).where(created_by: 101).order(:published_on).offset(1)
  posts.map(&:id)           #=> [8, 9]

  # LIMIT: get posts for blog_id=2 AND created_by=2 order_by published_on and just the second one
  posts = API::Post.where(blog_id: 2).where(created_by: 101).order(:published_on).offset(1).limit(1)
  posts.map(&:id)           #=> [8]

  post = API::Post.where(blog_id: 2).where(created_by: 101).order(:published_on).offset(1).limit(1).first
  post.id                   #=> 8
  post.blog_id              #=> 2
  post.created_by           #=> 101
  post.published_on         # '2014-06-21'
````

> NOTE: Since `offset` and `limit` can be chained together, you can use these
> with your favorite paginator.

In all of these cases, Daylight issues only one request per search.
See [Request Parameters](develop.md#request-parameters) for further reading.

Just like `ActiveRecord`, each part of the chain has its own context and can be
inspected individually.

  ````ruby
    published_posts = API::Post.published
    first_published = published_posts.order(:published_on).first

    first_published.id         #=> 2
    published_posts.map(&:id)  #=> [3, 2, 7, 5, 6, 1, 9, 8]
  ````

Here you can see a result set can be further refined while not affecting the
original result set.

---

## Associations

Associations work as they do today in `ActiveResource` with one notable
exception: client models will perform the lookup for associated objects
server-side.

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

If you want to use the original behavior where the `foreign_key` is used to
lookup up associated objects, you can pass the `use: 'resource'` to the
`has_many` association.

  ````ruby
    has_many :comments, use: 'resource'
  ````

Like the default `ActiveResource` behavior, this will return a
`ActiveResource::Collection` that cannot be [chained](#chaining), nor can
[nested resources](#nested-resources) be set in the collection.

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
    post.author.full_name = "Reid MacDonald"
    post.author.save #=> true

    post = API::Post.first
    post.author.full_name #=> "Reid MacDonald"
  ````

This is the same as saying:

  ````ruby
    post = API::Post.first

    author = post.author
    author.full_name = "Reid MacDonald"
    author.save #=> true

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

As before with [chaining](#chaining) each part of the chain has its own context
and can be inspected individually.

  ````ruby
    first_published_post    = API::Post.published.first
    comments_with_images    = first_published_post.comments.where(has_images: true)
    my_last_edited_comment  = comments_with_images.where(created_by: 101)).order(:edited_on).last

    my_last_edited_comment.id       #=> 90
    comments_with_images.map(&:id)  #=> [32, 15, 1, 90, 81]
  ````

Here you can see a result set can be further refined while not affecting the
original result set fetched for the association.

---

## Building Objects

Most of the time, you want to check to see if an object already exists and if
it doesn't build that object.  `ActiveResource` already supplies this
functionality with `first_or_create` and `first_or_initialze`.

Daylight ensures that these methods work with refinements & chaining and
ensures the requests are properly formatted for the server.

> NOTE: The refinements are expressive but can become very complicated quickly.
> Daylight uses the [where_values](develop.md#where_values) generated by the
> server to build the objects.

### `first_or_create`

The `first_or_create` method will save the object if it does not already exist.

  ````ruby
    post = API::Post.where(slug: '100-best-albums-of-2014').first_or_create
    post.new?   #=> false

    # set an attribute directly
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

### `first_or_initialize`

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

You can create an object based on a collection for an association.

> NOTE: Specifically, only a `has_many` association. The `belongs_to` or
> `has_one` asscoiations will have a `nil` object if they are not set
> (ie. there's no foriegn_key) and will not work.

For example  if there is no `comment` for the the `post`:

  ````ruby
    comment = API::Post.find(1).comments.first_or_initialize({
        message: "Am I the first comment?"
      })
    comment.new?    #=> true
    comment.post_id #=> 1
    comment.save    #=> true
  ````

You may apply any refinement to the association:

  ````ruby
    comment = API::Post.find(1).comments.where(is_liked: true).first_or_create
    comment.new?    #=> false
    comment.post_id #=> 1

    # Update the message
    comment.message = "You really like me when I said: '#{comment.message}'"
    comment.save    #=> true
  ````

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

> FUTURE [#9](https://github.com/att-cloud/daylight/issues/9):
> Remote methods cannot be further refined like associations

---

## Error Handling

A goal of Daylight is to offer better handling and messaging to the client when
expected errors occur.  This will aid in development of both the API and when
users of that API are having issues.

### Validation Errors

Daylight exposes validation errors on creates and updates.  Given a validation
on a model:

  ````ruby
  class Post < ActiveRecord::Base
    validates :title, presence: true
  end
  ````

When saving this model from the client errors will be exposed similar to
`ActiveRecord`:

  ````ruby
  post = API::Post.new
  post.save             # => false
  post.errors.messages  # => {:base=>["Title can't be blank"]}
  ````

With the introduction of and use of
[Strong Parameters](http://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)
unpermitted or missing attributes will be detected.

> FUTURE [#8](https://github.com/att-cloud/daylight/issues/8):
> Would be nice to know which parameter is raising the error and if it was a
> _required_ parameter or an _unpermitted_ one.

Lets say `created_at` is not permitted on the `PostController`:
  ````ruby
  post = API::Post.new(created_at: Time.now)
  post.save             # => false
  post.errors.messages  # => {:base=>["Unpermitted or missing attribute"]}
  ````

### Bad Requests

Daylight will raise an error on unknown attributes.  This differes from
`ActiveRecord` where it will be raised immediately because the error is
detected by `APIController` during a `save` action.

For example, given the same `Post` model above:
  ````ruby
  post = API::Post.new(foo: 'bar')
  post.save
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown attribute: foo
  ````

Similarly, Daylight raises errors on unknown keys, associations, scopes,
or remoted methods.  The error will be raise as soon as the request is
issued, not just on `save` actions.

For example, when providing an incorrect condition:
  ````ruby
  API::Post.find_by(foo: 'bar')
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown key: foo
  ````
If invalid statements are issued server-side they will be raised:

  ````ruby
  API::Post.published.limit(:foo)
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = invalid value for Integer(): "foo"
  ````

This is also useful developing and detecting errors in your client models
Given the client model:

  ````ruby
  class API::V1::Post < Daylight::API
    scopes :published
    remote :top_comments

    has_many :author
  end
  ````

If neither `published`, `top_comments`, nor `author` are not setup on the
server-side, errors will be raised.

  ````ruby
  API::Post.published
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown scope: published

  API::Post.by_popularirty
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown remote: top_comments

  API::Post.find(1).author
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown association: author
  ````

---

## Understanding Interaction

To help understand how requests from the client will produce load on the server
API, will aid in understanding what load is produced on the API server(s).

Daylight does its best to collect information about a query before issuing the
request, but can only do so much.  Daylight will still suffer from putting a
request in a tight loop as any other web application will.

###  Request Frequency

A request is issued for any query for a resource or collection of resources.
Everytime an association is traversed, a new request sent.   All the refinements
on a collection is sent along with the request.

Given a large request like:

````ruby
  API::Post.published.updated.find_by(slug: '100-best-albums-of-2014'). # Post request (with refinements)
    comments.edited.where(has_images: true).first.                      # Comment request (with refinements)
    images.liked.limit(1).                                              # Image request (with refinements)
    map(&:caption).first                                                # No request: iterating over data structure
````

There are 3 resources/collections retrieved from the server.  One each for
`post`, `comment`, and `image`.  You can see this in the API server logs:

    GET "/v1/posts.json?filters[slug]=100-best-albums-of-2014&limit=1&scopes[]=published&scopes[]=updated"
    GET "/v1/posts/8/comments.json?filters[has_images]=true&scopes[]=comments"
    GET "/v1/comments/1161/images.json?scopes[]=liked&limit=1"


Multi-step requests pretty much match up to the action being performed.
From our example on in the [README](../README.doc) we show creating a `post`
and `user` and associating the two:

    post = API::Post.find_by(slug: '100-best-albums-2014')
    post.author = API::User.find_or_create(username: 'reidmix')
    post.save

There are 3 queries to the server:

1. Initial lookup for the `post`
2. The creation of the `user`
3. Save the `post` to associate the newly created `user`

### Response Size

Responses are in JSON, but XML can be supported.  Response size depends
several factors:
1. The length of each attribute
1. The number of attributes per resource
2. The number of resources
3. The metadata

For example, for a collection of `posts`:

  ````json
    {
      "posts": [
        {
          "id": 1,
          "blog_id": "1",
          "title": "100 Best Albums of 2014",
          "created_by": "101",
          "slug": "100-best-albums-of-2014"
          "exerpt":"Ranked list of the 100 best albums so far in 2014",
          "body": "2014 is a year of many albums, here is a...",
          "published": true,
          "updated": false
        },
        {
          "id": 2,
          "blog_id": "1",
          "title": "100 Best Albums of All Time",
          "created_by": "101",
          "slug": "100-best-albums-of-all-time"
          "exerpt":"Ranked list of the 100 best albums evar.",
          "body": "Here is my favorite albums of all time...",
          "published": true,
          "updated": true
        }
      ],
      "meta": {
        "where_values": {
          "blog_id": 1
          },
        "post": {
          "read_only": [
            "slug",
            "published",
            "updated"
          ],
          "nested_resources": [
            "author",
            "comments"
          ]
        }
      }
    }
  ````

Here we show 2 posts, but imagine showing every `post` in each request.
Each time a request can be made that will reduce the size of the collection
will speed up response times from the server.

Metadata about the response and elements in the collection are also returned
per request.  Find out more about this in the
[API Developers Guide](develop.md#response-metadata)

For expensive requests, your API developers may automatically limit the
"page size" returned by the server and you will need to paginate through
the results.

Please refer to [Benchmarks](benchmarks.md#) for further reading
about response times between the client and the server.
