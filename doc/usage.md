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
* [ActiveResource Overview](#active-resource-overview)
* [Refinements](#refinements)
  * [Conditions](#conditions)
  * [Order](#order)
  * [Limit and Offset](#limit-and-offset)
  * [Scopes](#scopes)
  * [Chaining](#chaining)
* [Remote Methods](#remote-methods)
* [Associations](#associations)
  * [Nested Objects](#nested-objects)
  * [Building Objects](#building-objects)
  * [Updating Objects](#updating-objects)
  * [More Chaining](#more-chaining)
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
      scope :published

      belongs_to :blog
      belongs_to :author, class_name: 'api/v1/user'

      has_one :company, through: :blog

      has_many :comments
      has_many :commenters, through: :associated, class_name: 'api/v1/user'

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

> NOTE: Daylight add a [limit](#limit) condition to get the first `Post` as an
> optimization.  There is no optimization for `last` as it is equivalent to
> `Post.all.to_a.last`

You can `create`, `update`, `delete` a `Post`.  Here's an example of an `update`:

  ````ruby
    post = API::Post.find(1)  #=> #<Bluesky::V1::Zone:0x007ffa8c44fde8 ..>
    post.title = "100 Best Albums of All Time"
    post.save                 #=> true
  ````

Get associated records:

  ````ruby
    post = API::Post.find(1)  #=> #<API::V1::Post:0x007ffa8c44fde8 ..>
    post.comments             #=> [#<API::V1::Comment:0x007ffa8c4843b8 ..>,
                              #    #<API::V1::Comment:0x007ffa8c48e728 ..>, ...]
  ````

Search across the collection of records:

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

---

## Refinements

Daylight offers many ways to refine queries across collections.  These include
conditions, scopes, order, offset, and limit.

### Conditions

There are several additions to `ActiveResource` conditions.

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

And you can `offset` which records to be returned:

  ````ruby
    posts = API::Post.all
    posts.map(&:id)  #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    posts = API::Post.offset(5)
    posts.map(&:id)  #=> [6, 7, 8, 9, 10]
  ````

### Scopes

### Chaining

All of the above refinements are as limited to the one being used.  Daylight
allows all of the refinements to be chained together for better searches:

  ````ruby
    # get all posts
    posts = API::Post.all
    posts.map(&:id)  #=> [10, 3, 2, 4, 7, 5, 6, 1, 9, 8]

    # get posts for blog_id=2
    posts = API::Post.where(blog_id: 2)
    posts.map(&:id)           #=> [2, 1, 5, 9, 8]
    posts.map(&:blog_id)      #=> [2, 2, 2, 2, 2]

    # get posts for blog_id=2 AND created_by=2
    posts = API::Post.where(blog_id: 2).where(created_by: 101))
    posts.map(&:id)          #=> [2, 9, 8]
    posts.map(&:created_by)  #=> [101, 101, 101]

    # get posts for blog_id=2 AND created_by=2 order by published_on
    posts = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on)
    posts.map(&:id)           #=> [2, 8, 9]
    posts.map(&:published_on) #=> ['2014-01-01', '2014-06-21', '2014-06-26']

    # get posts for blog_id=2 AND created_by=2 order by published_on after the first one
    posts = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on).offset(1)
    posts.map(&:id)           #=> [8, 9]

    # get posts for blog_id=2 AND created_by=2 order_by published_on
    posts = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on).offset(1).limit(1)
    posts.map(&:id)           #=> [8]

    post = API::Post.where(blog_id: 2).where(created_by: 101)).order(:published_on).offset(1).limit(1).first
    post.id                   #=> 8
    post.blog_id              #=> 2
    post.created_by           #=> 101
    post.published_on         # '2014-06-21'
  ````

> NOTE: In all of these cases, Daylight issues only one request per search.
> See [Request Parameters](develop.md#request-parameters) for further reading.

Since `offset` and `limit` can be chained together, you can use these with your favorite paginator.


## Remote Methods

---

## Associations

### Nested Objects

If your model `accepts_nested_attributes_for` on the `blog` association, you
may re-associate it:

  ````ruby
    post = Daylight::Post.first

    post.blog.id #=> 1
    post.blog = API::Blog.find(2)
    post.save    #=> true

    post = Daylight::Post.first
    post.blog.id #=> 2
  ````


> NOTE: There is alignment with `has_one :through` built in Daylight to match
> Rails way of doing things.

You can chain `accepts_nested_attributes_for` to update these
`has_one :through` associations.  For example, if both:
* `Post` `accepts_nested_attributes_for :blog`
* `Blog` `accepts_nested_attributes_for :company`
Then you can re-associate the  `Company` on the `Post` itself:

  ````ruby
    post = Daylight::Post.first

    post.blog.id #=> 1
    post.company = API::Company.find(3)
    post.save    #=> true

    post = Daylight::Post.first
    post.company.id #=> 2
  ````

> FUTURE [#5](https://github.com/att-cloud/daylight/issues/5):
> Updates on the `has_one` and `belongs_to` association do not get propagated
> and should be.  Currently, only re-associations are propagated.

Saving the parent class doesn't save updates to the associations.  You can
save these associated instances directly:

  ````ruby
    post = Daylight::Post.first
    post.blog.name #=> "My Blog"
    post.blog.name = "Reidmix"
    post.blog.save #=> true

    post = Daylight::Post.first
    post.blog.name #=> "Reidmix"
  ````

### Building Objects

#### `find_or_intialize`
#### `find_or_create`

### Updating Objects

#### Records
#### Collections
#### Associations

### More Chaining

---

## Error Handling

---

## Understanding Interaction

###  Request Frequency

`Bluesky::Zone.nonretired.production.find_by(code: 'sql1').tenants.find_by(name: 'nosql-accenture-dev').vms.running`

Started GET "/v1/zones.json?filters%5Bcode%5D=sql1&limit=1&scopes%5B%5D=nonretired&scopes%5B%5D=production"
Started GET "/v1/zones/8/tenants.json?filters%5Bname%5D=nosql-accenture-dev&limit=1"
Started GET "/v1/tenants/1161/vms.json?scopes%5B%5D=running"

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

