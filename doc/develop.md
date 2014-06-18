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
  * [Controllers](#controllers)
  * [Serializers](#serializers)
  * [Routes](#routes)
  * [Client](#client)
* [Error Handling](#error-handling)
* [Underlying Interaction](#underlying-interaction)
  * [Symantic URLs](#symantic-urls)
  * [Request Params](#request-params)
  * [Symantic Data](#symantic-data)
  * [Response Metadata](#response-metadata)
* [Framework Links](#framework-links)

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

> Note: Daylight expects an model object or a collection when parsing results
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

> Note: ActiveResource looks up associations using foriegn keys but with
> Daylight you can call the associations defined on your model directly.

This is especially useful when you wish to preserve the richness of options on
your associations that are neccessary for your application to function
correctly.  For example:

  ````ruby
  class Post
    has_many :comments
    has_many :author, foreign_key: 'created_by_user_id', class_name: 'User'
    has_many :commenters, -> { uniq }, through: :comments, class_name: 'User'
    has_many :suppressed_comments, -> { where(spam: true) }, class_name: 'Comment'
  end
  ````

Here we have 4 examples where using the model associations are neccesary.  When
there is:

1. A configured foreign_key as in `author`
2. A through association as in `commenters`
3. A condindition block as `commenters` and `suppressed_comments` (eg. `uniq`
   and `where`)
4. A class_name in all three `author`, `commenters`, and `suppressed_comments`

ActiveResource will not be able to resolve these associations correctly without
using the model-based associations, because it:
* Cannot determine endpoint or correct class to instanciate
* Uses the wrong lookup key (in through associations and foreign key option)
* Conditions will not be supplied in the request

> Note: Daylight includes `Daylight::Refiners` on all models that inheret from
> `ActiveRecord::Base`.  At this time there is no way to exclude this module
> from any model.

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

> Note: Any functionality built in `ApplicationController` will be available to
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

      @post.update_attributes(:last_viewed_at, Time.now)
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
scopes, conditions, order, limit, and offset.

You can find more information on how to use these refinements in the
[Daylight Users Guide](guide.md)

##### Remoted

Any public method is allowed to be called on the model instance by use of the
`remoted` method added by `Daylight::Refiners`.  Which public methods are
allowed are defined in your [Routes](#routes).

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

> Note: To understand how `root` option is being used in both `assoicated`
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

> Note: Daylight calls the instance variables for specialized actions
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

### Serializers

### Routes

### Client

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

> Future: it would be nice to know which paramter and if it was a required
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
    remote :by_popularity

    has_many :author, through: :associated
  end
  ````

If neither `published`, `by_popularity`, nor `author` are not setup on the
server-side, errors will be raised.

  ````ruby
  API::Post.published
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown scope: published

  API::Post.by_popularirty
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown remote: by_popularity

  API::Post.find(1).author
  #=> ActiveResource::BadRequest: Failed.  Response code = 400.
  #   Response message = Bad Request.  Root Cause = unknown association: author
  ````

## Underlying Interaction

### Symantic URLs

### Request Parameters

### Symantic Data

### Resposne Metadata

## Framework Links

To better understand how a framework extends or alters the underlying Rails
technology.  Here are some additional details on how Daylight was built:

* [Framework Overview](framework.md)
* [Build Environment](environment.md)
* [Guiding Principles](principles.md)
