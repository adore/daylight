# API Developer Guide

Daylight uses the MVC model provided by Rails to divide labor of an API request
with some constraints.

Instead of views, serializers are used to generate JSON/XML.  Routes have a
great importance to the definition of the API.  And the client becomes the
remote proxy for all API requests.

To better undertand Daylight's interactions, we define the following components:
* Rails **model** is the canonical version of the object
* A **serializer** defines what parts of the model are exposed to the client
* Rails **controller** defines which actions are performed on the model
* Rails **routes** defines what APIs are available to the client
* The **client** model is the remote representation of the Rails model

#### Table of Contents
* [Expectations](#expectations)
* [Building Your API](#building-your-api)
  * [Models](#models)
  * [Serializers](#serializers)
  * [Controllers](#controllers)
  * [Routes](#routes)
  * [Client](#client)
* [Underlying Interaction](#underlying-interaction)
  * [Symantic URLs](#symantic-urls)
  * [Request Params](#request-params)
  * [Symantic Data](#symantic-data)
  * [Response Metadata](#response-metadata)


## Expectations


* **Rails 4**: Daylight was built only using the most current version of Rails
  4
* **Namespace APIs**: Client Models are all namespaced, by default under `API`
  (namespace is customizable)
* **Versioned APIs**: URLs will be versioned, by default `v1` is the current
  and only version (versions are customizable)
* **ActiveModelSerializer**: Serialization occurs via
  `ActiveModel::Serailizer`, typically in JSON

## Building Your API

Building your Client from the bottom up you will need to develop your models,
controllers, routes that you are familiar with today.  Add serializers to
describe the JSON generation of your object.  Finally, build your client models
based on the API actions available and the response from the server.

### Models

Models are built exactly as they are in Rails, no changes are neccessary.

Through specifiecation on the routes, Daylight allows you to make scopes and
methods available to the client.

> NOTE: Daylight expects an model object or a collection when parsing results
> from a model method.

You can chose to allow models to be created, updated, and associated through
a "parent" model using the `accepts_nested_attributes_for` mechansism.

  ````ruby
    class Post < ActiveRecord::Base
      has_many :comments

      accepts_nested_attributes_for :comments
    end
  ````

Once the client is setup you can do the following:

  ````ruby
  post = API::Post.find(1)
  post << API::Comment.new(text: "This is an awesome post")
  post.save
  ````

> INFO: ActiveResource looks up associations using foriegn keys but with
> `Daylight` you can call the associations defined on your model directly.

This is especially useful when you wish to preserve the richness of options on
your associations that are neccessary for your application to function
correctly.  For example:

  ````ruby
    class Post
      has_many :comments
      has_many :favorites, foreign_key: 'favorite_post_id', class_name: 'User'
      has_many :commenters, -> { uniq }, through: :comments, class_name: 'User'
      has_many :suppressed_comments, -> { where(spam: true) }, class_name: 'Comment'
    end
  ````

Here we have 4 examples where using the model associations are neccesary.  When
there is:

1. A configured foreign_key as in `favorites`
2. A through association as in `commenters`
3. A condindition block as `commenters` and `suppressed_comments` (eg. `uniq`
   and `where`)
4. A class_name in all three `favorites`, `commenters`, and `suppressed_comments`

ActiveResource will not be able to resolve these associations correctly without
using the model-based associations, because it:
* Cannot determine endpoint or correct class to instantiate
* Uses the wrong lookup key (in through associations and foreign key option)
* Conditions will not be supplied in the request

> NOTE: Daylight includes `Daylight::Refiners` on all models that inherit from
> `ActiveRecord::Base`.  At this time there is no way to exclude this module
> from any model. It does not modify existing ActiveRecord functionality.

---

### Serializers


Daylight relies heavily on
[ActiveModelSerializers](https://github.com/rails-api/active_model_serializers)
and most information on how to use and customize it can be found in their
[README](https://github.com/rails-api/active_model_serializers/blob/master/README.md).
Serialize only the attributes you want to be public in your API.  This allows
you to have a separation between the model data and the API data.

> NOTE: Make sure to include `:id` as an attribute so that Daylight will be
> able to make updates to the models correctly.

For example, `id`, `title` and `body` are exposed but there all other
attributes are not serialized:

  ````ruby
    class PostSerializer < ActiveModel::Serializer
      attributes :id, :title, :body
    end
  ````

We encourage you to embed only ids to keep payloads down. Daylight will make
additional requests for the associated objects when accessed:

  ````ruby
    class PostSerializer < ActiveModel::Serializer
      embed :ids

      attributes :id, :title, :body

      has_one :category
      has_one :author, key: 'created_by'
    end
  ````
> NOTE: Make sure to use `key` option in serializers, not `foreign_key`

> INFO: `belongs_to` associations can be included using `has_one` in your
> serializer

There isn't any need for you to include your `has_many` associations in
your serializer.  These collections will be looked up from the Daylight
client by a seperate request.

The serializer above will generate JSON like:

  ````json
    {
      "post": {
        "id": 283,
        "title": "100 Best Albums of 2014",
        "body": "Here is my list...",
        "category_id": 2,
        "created_by": 101
      }
    }
  ````

There are 2 main additions Daylight adds to `ActiveModelSerializer` to enable
functionality for the client.  They are _through associations_ and _read only
attributes_.

#### `has_one :through`

In Rails you can setup your model to have a `has_one :through`.  This is a
special case for `ActiveModelSerializers` and for the Daylight client.

> NOTE: Rails does not have `belongs_to :through` associations.

For example, if your model has associations setup like so:

  ````ruby
    class Post < ActiveRecord::Base
      belongs_to :blog
      has_one :company, through: :blog
    end
  ````

To configure the `PostSerializer` to correctly use this through association
set it up like similarly to your model.

  ````ruby
    class PostSerializer < ActiveModel::Serializer
      embed :ids

      attributes :id, :title, :body

      has_one :blog # `has_one` in a serializer
      has_one :company, through: :blog
    end
  ````

This will create a special embedding in the JSON that the client will be able
to use to lookup the association:

  ````json
    {
      "post": {
        "id": 283,
        "title": "100 Best Albums of 2014",
        "body": "Here is my list...",
        "blog_id": 4,
        "blog_attributes": {
          "id": 4,
          "company_id": 1
        },
      }
    }
  ````

There's duplication in the JSON payload, but `post["blog_id"]` and
`post["blog_attributs"]["id"]` are used for different purposes.

  ````ruby
    API::Post.first.blog      #=> uses "blog_id"
    API::Post.first.company   #=> uses "blog_attributes"
  ````

> INFO: `blog_attributes` are also used for `accepts_nested_attributes_for`
> mechansism.

#### Read Only Attributes

There are cases when you want to expose data from the model as read only
attributes so they cannot be updated.  These cases are when the attribute is:
* Evaluated and not stored in the database
* Stored into the database only when computed
* Readable but should not be updated

Here we have a `Post` object that does all three things. Assume there are
`updated_at` and `created_at` immutable attributes as well.

  ````ruby
    class Post < ActiveRecord::Base
      before_create do
        self.slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
      end

      def published?
        published_at.present?
      end
    end
  ````

To configure the `PostSerializer` to mark these attributes as read only:

  ````ruby
    class PostSerializer < ActiveModel::Serializer
      embed :ids

      attributes :id, :title, :body
      read_only :created_at, :updated_at, :slug, :published?
    end
  ````

These attributes will be marked as read only in a special
[Metadata](#resposne-metadata) section in the object's JSON.

The client will be able to read each of these values but will raise a
`NoMethodError` when attempting to write to them.

  ````ruby
    post = API::Post.first
    post.created_at       #=> "2014-05-02T19:58:09.248Z"
    post.slug             #=> "100-best-albums-of-2014"
    post.published?       #=> true

    post.slug = '100-best-albums-of-all-time'
    #=> NoMethodError: Cannot set read_only attribute: display_name
  ````

Because these attributes are read only, the client will exclude them from
being sent when the object is saved.

  ````ruby
    post.title = "100 Best Albums of All Time"
    post.save  #=> true
  ````

In this case `published?`, `slug`, `created_at`, and `updated_at` are never
sent in a PUT update.

---

### Controllers


Controllers can be written without Daylight, but often times you must develop
boilerplate code for `index`, `create`, `show`, `update`, and `delete` actions.
Also, you may chose controllers that are for the API and controllers that are
for your application.

Daylight simplifies building API controllers:

  ````ruby
    class PostController < APIController
    end
  ````

> NOTE: Any functionality built in `ApplicationController` will be available to
> your `APIController` subclasses.

Since your controller is a subclass of `ActiveController::Base` continue to add
your own actions and routes for them as you do today in Rails.

There are predefined actions provided by Daylight, that handle both REST
actions and some specialized cases.

You must "turn on" these prede actions.  Actions provided by Daylight are
turned off by default so what is exposed is determined by the developer.

For example, to turn on `show` action:

  ````ruby
    class PostController < APIController
      handles :show
    end
  ````

This is equivalent to;

  ````ruby
    class PostController < APIController
      def show
        render json: Post.find(params[:id])
      end
    end
  ````

Daylight uses the name of the controller to determine the related model to use.
Also, the `primary_key` name is retrived from that determined model.  In fact,
all of the actions are just ruby methods, so you can overwrite them (and call
super) as you see fit:

  ````ruby
    class PostController < APIController
      handles :show

      def show
        super

        @post.update_attributes(:view_count, @post.view_count+1)
      end
    end
  ````

To turn on multiple actions:

  ````ruby
    class PostController < APIController
      handles: :create, :show, :update, :destroy
    end
  ````

Or you can turn them all (including the [Specialized Actions](#specialized-actions)):

  ````ruby
    class PostController < APIController
      handles: :all
    end
  ````

For your reference, you can review the code of the equivalent actions in
[Controller Actions](actions.md)

####  Specialized Actions

Much of Daylight's features are offered through specialized controller actions.
These specialized actions are what enables:
* [Query Refinements](#index)
* [Model Associations](#associated)
* [Remote Methods](#remoted)

##### Index

You can refine queries of a resources collection by scopes, conditions, order,
limit, and offset.

This is accomplished with a method called `refine_by` which is added to your
models added by `Daylight::Refiners`

On the controller, see it called on the `index` action:

  ````ruby
    class PostController < APIController
      def index
        render json: Post.refine_by(params)
      end
    end
  ````

##### Associated

Associations called through the model instance is accomplished using a method
called `associated` added by `Daylight::Refiners`.  Which associations allowed
are defined in your [Routes](#routes).

On the controller, see it called by the (similarly named) `associated` action:

  ````ruby
    class PostController < APIController
      def associated
        render json: Post.associated(params), root: associated_params
      end
    end
  ````

Associations can also be refined similarly to `index` where you can specify
scopes, conditions, order, limit, and offset.  The associated action is
setup in [Through Associations](#through-associations) on the client model.

> NOTE: You can find more information on how to use these refinements in
> the [Daylight Users Guide](usage.md)

##### Remoted

Any public method is allowed to be called on the model instance by use of the
`remoted` method added by `Daylight::Refiners`.  Which public methods are
allowed are defined in your [Routes](#routes).

> FUTURE [#4](https://github.com/att-cloud/daylight/issues/4):
> It would be nice to allow public methods on the model class to be exposed and
> called against the collection.

Remoted methods should return a record or collections of records so that they
may be instantiated correctly by the client and act as a proxy back to the API.

On the controller, see it called by the (similarly named) `remoted` action:

  ````ruby
    class PostController < APIController
      def remoted
        render json: Post.remoted(params), root: remoted_params
      end
    end
  ````

All of the specialized actions can be enabled on your controller like the REST
actions:

  ````ruby
    class PostController < APIController
      handles :index, :associated, :remoted
    end
  ````

They are also included when specifying `handles :all`.

> INFO: To understand how `root` option is being used in both `assoicated`
> and `remoted` please refer to the section on
[Symantic Data](#associated-and-remoted-responses)

#### Customization

Behind the scenes, the controller actions look up models based on its controller
name.  The portion before the word _Controller_ (ie. when `PostController` is
the controller name it determines the model name to be `Post`).

You may specify a different model to use:

  ````ruby
    class WelcomeController
      set_model_name :post
    end
  ````

In `create`, `show`, `update` and `destroy` actions (member) results are stored
in an instance variable.  The instance variable name is based on the model
name (ie. when `PostController` is the controller name the instance variable is
called `@post`).

In `index`, `associated`, and `remoted` specialized actions results are stored
in an instance variable simply called `@collection`

Both of these instance variables may be customized:

  ````ruby
    class PostController
      set_record_name :result
      set_collection_name :results
    end
  ````

> NOTE: Daylight calls the instance variables for specialized actions
>`@collection` because in `associated` and `remoted` actions the results may be
> any type of model instances.

In all customizations can use a string, symbol, or constant as the value:

  ````ruby
    class PostController
      set_model_name Post
      set_record_name 'result'
      set_collection_name :results
    end
  ````

Lastly, your application may already have an APIController and there could be
a name collision.  Daylight will not use this constant if it's already defined.

In this case use `Daylight::APIController` to subclass from:

  ````ruby
    class PostController < Daylight::APIController
      handles :all
    end
  ````

---

### Routes

Setup your routes as you do in Rails today.  Since Daylight assumes that
your API is versioned, make sure to employ `namespace` in routes or use
a simple, powerful tool like
[Versionist](https://github.com/bploetz/versionist).


  ````ruby
    API::Application.routes.draw do
      namespace :v1 do
        resources :users, :posts, :comments
      end
    end
  ````

You can modify the actions on each reasource as you see fit, matching your
`APIController` actions:

  ````ruby
    API::Application.routes.draw do
      namespace :v1 do
        resources :users, :posts
        resources :comments, except: [:index, :destroy]
      end
    end
  ````


To expose model assoications, you can do that with Daylight additions to
routing options.

> FUTURE [#7](https://github.com/att-cloud/daylight/issues/7):
> The cliento only supports model associations on `has_many` relationships.  We
> will need to evaluate the need to support model associations on `has_one` and
> `has_many` (as we never had a case for it)

  ````ruby
    API::Application.routes.draw do
      namespace :v1 do
        resources :users,     associated: [:posts, :comments]
        resources :posts,     associated: [:comments]
        resources :comments,      except: [:index, :destroy]
      end
    end
  ````

Any of the rich `has_many` relationships setup may be exposed as a model
associations, choose which ones to expose:

  ````ruby
    API::Application.routes.draw do
      namespace :v1 do
        resources :users,     associated: [:comments, :posts]
        resources :posts,     associated: [:authors, :comments, :commenters]
        resources :comments,      except: [:index, :destroy]
      end
    end
  ````

To expose remoted methods, you can do that with Daylight additions to
routing options.

  ````ruby
    API::Application.routes.draw do
      namespace :v1 do
        resources :users,     associated: [:comments, :posts]
        resources :posts,     associated: [:authors, :comments, :commenters],
                                 remoted: [:top_comments]
        resources :comments,      except: [:index, :destroy]
      end
    end
  ````

As you can see when you develop your API, the routes file becomes a
specification of what is exposed to the client.

---

### Client

The client is where all our server setup is put together.  Client models
subclass from `Daylight::API` classes.

> INFO: `Daylight::API` subclasses `ActiveResource::Base` and extends it

You can build your client model as you do today as an `ActiveResource::Base`
as all functionality performs the same out of the box. (Only when using
Daylight features is when Daylight additions to `ActiveResource` enabled)

  ````ruby
    class API::V1::Post < Daylight::API
    end
  ````

Here again, we encourage you to namespace and version your client models.
You can do this using module names and Daylight will offer several
conviniences.

#### Aliased API

Daylight will _alias_ to the current version defined in your `setup!`.
Assuming you've have two versions of your client models:

  ````ruby
    Daylight::API.setup!(version: 'v1', versions: %w[v1 v2])
    API::Post  #=> API::V1::Post

    Daylight::API.setup!(version: 'v2')
    reload!

    API::Post  #=> API::V2::Post
  ````

Using the aliased versions of your API is practical for your end users.  They
will not need to update all of the constants in their codebase from
`API::V1::Post` to `API::V2::Post` after they migrate. Instead they can focus
on differences provided in the new API version.


> FUTURE [#2](https://github.com/att-cloud/daylight/issues/2):
> It may be possible to have different versions of a client model to run
> concurrently.  This would aid end users of the API to move/keep some classes
> on a particular version.

#### Client Reloader

When developing your API when you `reload!` within your console, the aliased
constants will still reference the older class definitions.  Currently, this
only works with IRB.  To re-alias the constants during a `reload!` add the
following to an initializer:

  ````ruby
    require 'daylight/client_reloader'
  ````

This should not be needed for your end-users but is available for debugging
purposes if needed.

#### Association Lookup

Daylight will lookup association classes using the namespace and version set
in your client.  This simplifies setting up your relationships becaause you do
not need to define your `class_name` on each association:

  ````ruby
    class API::V1::Post < Daylight::API
      belongs_to :blog

      has_many :comments
    end
  ````

Once all client models are setup, associationed models will be fetched and
initialized:

  ````ruby
    post = Daylight::Post.first

    post.blog       #=> #<API::V1::Blog:0x007fd8ca4717d8 ...>
    post.comments   #=> [#<API::V1::Comment:0x007fd8ca538ce8...>, ...]
  ````

There are times when you will need to specify a client model just like you do
in `ActiveRecord`:

  ````ruby
    class API::V1::Post < Daylight::API
      belongs_to :author, class_name: 'api/v1/user', foreign_key: 'created_by'
      belongs_to :blog

      has_many :comments
    end
  ````

> NOTE: The foreign key needs to match the same key in your serailizer and the
> `foreign_key` in your `ActiveRecord` model.

The `User` will be correctly retrieved for the `author` association:

  ````ruby
    Daylight::Post.first.author   #=> #<API::V1::User:0x007fd8ca543e90 ...>
  ````

#### Through Associations

There are two types of Through Associations in Daylight:
* `has_one :through`
* `has_many :through`


First, once you've setup your [`has_one :through`](#has_one-through)
association in your model and serializer.  You can use it in the client model.
This is setup similar to the `ActiveRecord` model:

  ````ruby
    class API::V1::Post < Daylight::API
      belongs_to :blog
      has_one    :company, through: :blog
    end
  ````

The associations will be available:

  ````ruby
    post = API::Post.first
    post.blog     #=> #<API::V1::Blog:0x007fd8ca4717d8 ...>
    post.company  #=> #<API::V1::Company:0x007f8f83f30b28 ...>
  ````

Second, once the `has_many :through` associations are exposed in the
[Routes](#routes) you can them up in the client model:

  ````ruby
    class API::V1::Post < Daylight::API
      has_many 'comments'
      has_many 'commenters', through: :association
    end
  ````

The value is always `:association` and is a directive to Daylight to use the
[associated](#associated) action on the `PostController`.

The associations will be available:

  ````ruby
    post = API::Post.first
    post.comments    #=> [#<API::V1::Comment:0x007f8f83f91c20 ...>, ...]
    post.commenters  #=> [#<API::V1::Company:0x007f8f83fe1f40 ...>, ...]
  ````

Here we can see a typical `ActiveResource` association for `comments`is used
along-side our `has_many :through`.  If there is no reason to use the model
assoication, the flexibility is up to you.  Please review the reasons to use
[Model Association](#models).


You can setup both to use model associations:
  ````ruby
    class API::V1::Post < Daylight::API
      has_many 'comments',   through: :association
      has_many 'commenters', through: :association
    end
  ````

Refer to the [Daylight Users Guide](usage.md) to see how to further work
associations.

#### Scopes and Remoted Methods

Adding adding scopes and remoted methods are very simple.


Given the `ActiveRecord` model setup:

  ````ruby
    class Post < ActiveRecord::Base
      scope :published,     -> { where(published: true) }
      scope :by_popularity, -> { order_by(:view_count) }

      def top_comments
        comments.order_by(:like_count)
      end
    end
  ````

Remoted methods are available once the [remoted](#remoted) action is handled
by the controller and the method name is included in your [routes](#routes).

> FUTURE [#6](https://github.com/att-cloud/daylight/issues/6):
> Scopes may need to be whitelisted like remoted methods.

Then you can setup the your client model:

  ````ruby
    class API::V1::Post < Daylight::API
      scopes :published, :by_popularity
      remote :top_comments
    end
  ````
And used like so:


  ````ruby
    API::Post.published.by_popularity #=> [#<API::V1::Post:0x007f8f890219b0 ...>, ...]
    API::Post.top_comments            #=> [#<API::V1::Comment:0x007f8f89050da0 ...>, ...]
  ````

> FUTURE [#9](https://github.com/att-cloud/daylight/issues/9):
> Remote methods cannot be further refined like associations

## Underlying Interaction

This section is to help  understanding what the client is doing so you can
access your API server directly through your browers.  This is useful for
triaging bugs, but also can help examining requests and responses.

> NOTE: This information can be used for when a client would need to be
> built in another platform or language but wishes to use the server API.

### Symantic URLs

Daylight strives to continue to keep its API URLs symantic and RESTful.
`ActiveResource` does most of the work:

    HTTP       URL                                                      # ACTION                CLIENT EXAMPLE

    GET        /v1/posts.json                                           # index                 API::Post.all
    POST       /v1/posts.json                                           # create                API::Post.create({})
    GET        /v1/posts/1.json                                         # show                  API::Post.find(1)
    PATCH/PUT  /v1/posts/1.json                                         # update                API::Post.find(1).update_attributes({})
    DELETE     /v1/posts/1.json                                         # destroy               API::Post.find(1).delete


Daylight adds to these symantic URLs with the `associated` and `remoted`
actions.  In fact, they look similar to nested URLs:

    HTTP       URL                                                      # ACTION                CLIENT EXAMPLE

    GET        /v1/posts/1/comments.json                                # associated            API::Post.find(1).comments
    GET        /v1/posts/1/top_comments.json                            # remoted (collection)  API::Post.find(1).top_comments
    GET        /v1/posts/1/statistics.json                              # remoted (record)      API::Post.find(1).statistics

By URL alone, there's no way to distinguish between `associated` and `remoted`
requests (they are not RESTful per se).  For all intents and purposes they
both are an associated data nested in a member of a `Post`.

To treat them differently, both the client and the server need to have
knowledge about what kind of specialized action they are.  On the server this
is done through [Routes](#routes).  On the client model, this is done by
setting up `remote` and `scopes`

The difference is in the response:
* `associated` is always a collection
* `remoted` may be a single record or a collection

> FUTURE [#4](https://github.com/att-cloud/daylight/issues/4):
> Is there any reason why `remoted` couldn't just be an `associated` from the
> client point of view?

### Request Parameters

Daylight supports scopes, conditions, order, limit, and offset.  Together these
are called refinements.  All of these refiniments are supplied through request
parameters.

    HTTP       URL                                                      # PARAMETER TYPE        CLIENT EXAMPLE

    GET        /v1/posts.json?order=created_at                          # Literal               API::Post.order(:created_at)
    GET        /v1/posts.json?limit=10                                  # Literal               API::Post.limit(10)
    GET        /v1/posts.json?offset=30                                 # Literal               API::Post.offset(30)
    GET        /v1/posts.json?scopes=published                          # Literal               API::Post.published
    GET        /v1/posts.json?scopes[]=published&scopes[]=by_popularity # Array                 API::Post.published.by_popularity
    GET        /v1/posts.json?filters[tag]=music                        # Hash                  API::Post.where(tag: "music")
    GET        /v1/posts.json?filters[tag][]=music&[tag][]=best-of      # Hash of Array         API::Post.where(tag: %w[music best-of])


None, one, or any combination of refinements can be supplied in
the request.  Combining all of the examples above:

  ````ruby
    API::Post.published.by_popularity.where(tag: %w[music best-of]).order(:created_at).limit(10).offset(30)
  ````

Will yield the following URL:

    /v1/posts.json?scopes[]=published&scopes[]=by_popularity&filters[tag][]=music&[tag][]=best-of&order=created_at&offset=30&limit=10

> NOTE: Collection of these parameters is how single requests to the server are
> are made by the client

Refinements are supported only on the `index` and `associated` actions because
these are requests for collections (as opposed to manipulating individual
members).

The only difference between `index` and `associated` is the target which the
refinements are applied.  For example:

    HTTP       URL                                                       # ACTION               TARGET

    GET        /v1/posts.json?order=created_at                           # index                Orders all Posts
    GET        /v1/posts/1/comments.json?order_created_at                # associated           Orders all Comments for Post id=1

### Symantic Data

Data transmitted in requests and responses are formatted the same and use
the same conventions.  Any data recieved can be encoded in a response without
any issues.

#### Root Element


Both requests and responses will have a root element.  For responses, root
elmeents define which client model(s) will be instantiated.  For requests,
root elements define the parameter key that object attributes are sent
under.

For an `Post` object, when encoded to JSON:

  ````json
    {
      "post": {
        "id": 1,
        "title": "100 Best Albums of 2014",
        "created_by": 101
      }
    }
  ````

For collection of `Post` objects, when encoded to JSON:

  ````json
    {
      "posts": [
        {
          "id": 1,
          "title": "100 Best Albums of 2014",
          },
        {
          "id": 2,
          "title": "Loving the new Son Lux album",
        }
      ]
    }
  ````

In both these cases, `post` is identified as the root, it's pluralized for
to `posts` for a collections.

#### Associated Attributes

Associations for `has_one` are delivered as specified by the
(serializers)[#serializer] and are embedded as IDs (eg. `blog_id`).
Foriegn key names (eg. `created_by`) when
specified are embedded as well:

  ````json
    {
      "zone": {
        "id": 1,
        "title": "100 Best Albums of 2014",
        "blog_id": 2,
        "created_by": 101
      }
    }
  ````

When setting a new object:

  ````ruby
    p.author = API::User.new({username: 'reidmix', fullname: 'Reid MacDonald'})
  ````

The new object will be updated using the `accepts_nested_attributes_for`
mechanism on `ActiveRecord`.  These attributes are passed along in its
own has which `accepts_nested_attributes_for` expects:

  ````json
    {
      "zone": {
        "id": 1,
        "title": "100 Best Albums of 2014",
        "author_attributes": {
          "username": "reidmix",
          "fullname": "Reid MacDonald"
        }
      }
    }
  ````

New items in a collections will be added to the existing set:

  ````ruby
    p.comments << API::Comment.new({created_by: 222, message: "New Comment"})
  ````

And will be encoded as an array:

  ````json
    {
      "zone": {
        "id": 1,
        "title": "100 Best Albums of 2014",
        "comments_attributes": [
          {
            "created_by": 101,
            "message": "Existing Comment"
          },
          {
            "created_by": 222,
            "fullname": "New Comment"
          }
        ]
      }
    }
  ````

> FUTURE [#10](https://github.com/att-cloud/daylight/issues/10):
> It would be useful to know which associations the client model
> `accepts_nested_attributes_for` so that we can turn "on/off"
> the setter for associated objects.

Lastly, `has_one :through` associations also uses the
`accepts_nested_attributes_for` mechanism to describe the relationship in an
attributes subhash.  For example

  ````json
    {
      "post": {
        "id": 283,
        "title": "100 Best Albums of 2014",
        "blog_id": 4,
        "blog_attributes": {
          "id": 4,
          "company_id": 1
        },
      }
    }
  ````

Our [previous example](#has_one-through) describes when a `Post` has a
`Company` through a `Blog`.  The `Blog` is referenced directly using the
`blog_id`.  `Company` is referenced _through_ the `Blog` using both of the
`blog_attribtues`.

#### Associated and Remoted Responses

The root element for the associated and remoted methods simply use the name of
the action in the response.

Typically this keeps things simple when retrieving `/v1/blog/1/top_comments.json`:

  ````json
    {
      "top_comments": [
        {
          "id": 2,
          "post_id": 1,
          "created_by": 101,
          "message": "Existing Comment"
        },
        {
          "id": 3,
          "post_id": 1,
          "created_by": 222,
          "fullname": "New Comment"
        }
      ]
    }
  ````

The associated and remoted methods will use configured name to look up the
client model.  In the case of `top_comments`, set the `class_name`
correct to the corresponding client model (ie. `api/v1/comment`)

### Response Metadata

Metadata about an object and its usage in the framework is delivered in the
`meta` section of the response data.  Anything can be stored in this section
(by the serializer).

For example:

  ````json
    {
      "post": {
        "id": 1,
        "title": "100 Best Albums of 2014",
      },
      "meta": {
        "frozen": true
      }
    }
  ````

It is retrieved using the `metadata` hash on the client model.

  ````ruby
    # example metadata that could specify when a Post cannot be updated
    Post.find(1).metadata[:frozen] #=> true
  ````

Daylight uses metadata in two standard ways:
* `read_only` attributes
* `where_values` clauses.

#### read_only

The way that Daylight know which methods are read only and cannot be written
is using the list of attributes that are `read_only` for that client model:

  ````json
    {
      "post": {
        "id": 1,
        "title": "100 Best Albums of 2014",
      },
      "meta": {
        "post": {
          "read_only": [
            "slug",
            "published",
            "created_at"
          ]
        }
      }
    }
  ````

Here, we will not be able to set `slug`, `published?`, and `created_at`
and Daylight will raise a `NoMethodError`

> NOTE: ActiveResource handles predicate lookups for attributes
> (eg. `published` vs. `published?`)


#### nested_resources

The way that Daylight know what Nested Resources are available to be set is
is using a list of classes that are `nested_resources` for that client model:

  ````json
    {
      "post": {
        "id": 1,
        "title": "100 Best Albums of 2014",
      },
      "meta": {
        "post": {
          "nested_resources": [
            "author",
            "comments"
          ]
        }
      }
    }
  ````

Here, we will be able to create or associate the `author` resource when creating
or updating a `post`.  We can also create a new `comment` and add it to the
collection in the same way.

> INFO: You can read up more in the User's Guide on how to use
> [Nested Resources](usage.md#nested-resources).

#### where_values

How Daylight keeps track of how a model was looked up when using
`find_or_initialize` and `find_or_create` is by returning the
`where_values` from ActiveRecord.  These will be merged when the
`ActiveResource` is saved.

  ````json
    {
      "post": {
        "id": 1,
        "title": "100 Best Albums of 2014",
      },
      "meta": {
        "where_values": {
          "blog_id": 1
        }
      }
    }
  ````

To see this in action, if the `Post` with the queried title was not found:

  ````ruby
    p = API::Blog.first.posts.find_or_create(title: "100 Best Albums of 2014")
    p.title   #=> "100 Best Albums of 2014"

    # from the `where_values` during the lookup
    p.blog_id #=> 1
  ````

Since, `where_values` clauses can be quite complicated and are resolved by
`ActiveRecord` we determine them server-side and send them as metadata in
the response.
