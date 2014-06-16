# API Developer Guide

Daylight uses the MVC model provided by Rails to divide labor of an API request with some constraints.

Instead of views, serializers are used to generate JSON/XML.  Routes have a great importance to the
definition of the API.  And the client becomes the remote proxy for all API requests.

To better undertand Daylight's interactions, we define the following components:
* Rails **model** is the canonical version of the object
* A **serializer** defines what parts of the model are exposed to the client
* Rails **controller** defines which actions are performed on the model
* Rails **routes** defines what APIs are available to the client
* The **client** model is the remote representation of the Rails model

## Models

## Controllers

## Serializers

## Routes

## Client
