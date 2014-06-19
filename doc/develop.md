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
* [Error Handling](#error-handling)
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
      has_many :authors, foreign_key: 'created_by', class_name: 'User'
      has_many :commenters, -> { uniq }, through: :comments, class_name: 'User'
      has_many :suppressed_comments, -> { where(spam: true) }, class_name: 'Comment'
    end
  ````

Here we have 4 examples where using the model associations are neccesary.  When
there is:

1. A configured foreign_key as in `authors`
2. A through association as in `commenters`
3. A condindition block as `commenters` and `suppressed_comments` (eg. `uniq`
   and `where`)
4. A class_name in all three `author`, `commenters`, and `suppressed_comments`

ActiveResource will not be able to resolve these associations correctly without
using the model-based associations, because it:
* Cannot determine endpoint or correct class to instanciate
* Uses the wrong lookup key (in through associations and foreign key option)
* Conditions will not be supplied in the request

> NOTE: Daylight includes `Daylight::Refiners` on all models that inheret from
> `ActiveRecord::Base`.  At this time there is no way to exclude this module
> from any model.


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
attributes so they cannot be updatedd.  These cases are when the attribute is:
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
> the [Daylight Users Guide](guide.md)

##### Remoted

Any public method is allowed to be called on the model instance by use of the
`remoted` method added by `Daylight::Refiners`.  Which public methods are
allowed are defined in your [Routes](#routes).

> FUTURE #4: It would be nice to allow public methods on the model class to
> be exposed and called against the collection.

Remoted methods should return a record or collections of records so that they
may be instanciated correctly by the client and act as a proxy back to the API.

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
> and `remoted` please refer to the section on [Symantic Data](#symantic-data)

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

> FUTURE #7: The cliento only supports model associations on `has_many`
> relationships.  We will need to evaluate the need to support model
> associations on `has_one` and `has_many` (as we never had a case for it)

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

### Client

The client is where all our server setup is put together.  Client models
subclass from `Daylight::API` classes.

> INFO: `Daylight::API` subclasses `ActiveResource::Base` and extends it

  ````ruby
    class API::V1::Post < Daylight::API
    end
  ````

Here again, we encourage you to namespace and version your client models.
You can do this using module names and Daylight will offer several
conviniences.

First, Daylight will _alias_ to the current version defined in your `setup!`.
Assuming you've have two versions of your client models:

  ````ruby
    Daylight::API.setup!(version: 'v1', versions: %w[v1 v2])
    API::Post  #=> API::V1::Post

    Daylight::API.setup!(version: 'v2')
    reload!

    API::Post  #=> API::V2::Post
  ````

Using the aliased versions of your API is practical for your end users.  They
will not need to update all of the constants in their code base from
`API::V1::Post` to `API::V2::Post` after they migrate and can focus on the
differences provided in the new API version.

> FUTURE #2: It may be possible to have different versions of a client model to
> run concurrently.  This would aid end users of the API to move/keep some
> classes on a particular version.

Second, Daylight will lookup association classes using the same module as your
client model.  This simplifies setting up your relationships becaause you do
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
assoication, the flexibility is up to you.  You can review the reasons to use
[Model Association](#models).


You can setup both to use model associations:
  ````ruby
    class API::V1::Post < Daylight::API
      has_many 'comments', through: association
      has_many 'commenters', through: :association
    end
  ````

Refer to the [Daylight Users Guide](guide.md) to see how to use work with these
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

Remoted methods are available once the [remoted](#remoted) method is turned on in
its controller and the method name is included in your [routes](#routes).

> FUTURE #6: Scopes may need to be whitelisted like remoted methods.

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

> FUTURE #9: Remote methods cannot be further refined like associations

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

> FUTURE #8: it would be nice to know which parameter and if it was a required
> parameter or an unpermitted one.

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
  API::Post.find(1).limit(:foo)
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = invalid value for Integer(): "foo"
  ````

This is also useful developing and detecting errors in your client models
Given the client model:

  ````ruby
  class API::V1::Post < Daylight::API
    scopes :published
    remote :top_comments

    has_many :author, through: :associated
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

## Underlying Interaction

### Symantic URLs

### Request Parameters

### Symantic Data

### Resposne Metadata
