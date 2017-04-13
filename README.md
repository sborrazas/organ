Organ
=====

Forms with integrated validations and attribute coercing.

Introduction
-----------

Organ is a small library for manipulating form-based data with validations
attributes coercion.

These forms are very useful for handling HTTP requests where we receive certain
parameters and need to coerce them, validate them and then do something with
them. They are made so that the system has 1 form per service, so the form
names should usually be very explicit of the service they are providing
(`CreateUser`, `DeleteUser`, `SendTweet`, `NotifyAdmin`).

You should reuse forms behaviour (including validations) through inheritance
or modules (like having `CreateUser` inherit from `UpdateUser`). They can be
extended to handle worker jobs, to act as presenters, etc.

They do not handle HTML rendering of forms or do any HTTP manipulation.

The name `Organ` was inspired by the fact that organs beheave in a module manner
so that they do one thing only.

Usage
-----

A form is simply a class which inherits from `Organ::Form`. You can specify
the attributes the form will have with the `attributes` class method.

The `attributes` class method takes the attribute name and any options that
attribute has.

The options can be:

* `:type` - The type for which that attribute will be coerced.
* `:skip` - If `true` it won't include the attribute when calling the
  `#attributes` method on the instance.
* `:skip_reader` - If `true`, it won't create the attribute reader for that
  attribute.

Example:

```ruby
class CreateCustomer < Organ::Form

  attribute(:name, :type => :string, :trim => true)
  attribute(:address, :type => :string, :trim => true)

  def validate
    validate_presence(:name)
    validate_length(:name, :min => 4, :max => 255)
    validate_length(:address, :max => 255)

    validate_uniqueness(:address) do |addr|
      Customer.where(:address => addr).empty?
    end
  end

  def perform
    Customer.create(attributes)
  end

end

# Sinatra example
post "/customer" do
  form = CreateCustomer.new(params[:customer])
  content_type(:json)
  if form.valid?
    form.perform
    status(204)
  else
    status(422)
    JSON.generate("errors" => form.errors)
  end
end
```

Default types
-------------

The default types you can use are:

### :string

Coerces the value into a string or nil if no value given. If the `:trim` option
is given it also strips the preceding/trailing whitespaces and newlines.

### :boolean

Coerces the value into false (if no value given) or true otherwise.

### :array

Coerces the value into an Array. If it can't be coerced into an Array, it
returns an empty Array. An additional `:element_type` option with another type
can be specifed to coerce all the elements of the array into it.

If a Hash is passed instead of an array, it takes the Hash values.

### :float

Coerce the value into a Float, or nil of the value can't be coerced into a
float.

### :hash

Coerces the value into a Hash. If it can't be coerced into a Hash, it returns
an empty Hash. An additional `:key_type` and/or `:value_type` can be specified
to coerce the keys/values of the hash respectively.

### :integer

Coerces the value into a Fixnum. If it can't be coerced it returns nil.

### :date

Coerces the value into a date. If the value doesn't have the `%Y-%m-%d` format
it returns nil.

Default validations
-------------------

### validate_presence

If the value is falsy or an empty string it appends a `:blank` error to the
attribute.

### validate_uniqueness

If the value is present and the block passed returns false, it appends a
`:taken` error to the attribute. Example:

```ruby
validate_uniqueness(:username) do |username|
  User.where(:username => username).empty?
end
```

### validate_email_format

If the value is present and doesn't match an emails format, it appends an
`:invalid` error to the attribute.

### validate_format

If the value is present and doesn't match the specified format, it appends an
`:invalid` error to the attribute.

### validate_length

If the value is present and shorter than the `:min` option, it appends a
`:too_short` error to the attribute. If it's longer than the `:max` option, it
appends a `:too_long` error to the attribute. Example:

```ruby
validate_length(:username, :min => 3, :max => 255)
validate_length(:first_name, :max => 255)
```

### validate_inclusion

If the value is present and not included on the given list it appends a
`:not_included` error to the attribute.

### validate_range

If the value is present and less than the `:min` option, it appends a
`:less_than` error to the attribute. If it's greater than the `:max` option, it
appends a `:greater_than` error to the attribute. Example:

```ruby
validate_range(:age, :min => 18)
```

### validation_block

This is a helper method that only calls the given block if the form doesn't have
any errors. This is particularly useful when some of the validations are costly
to make and unnecessary if the form already has errors.

```ruby
validate_length(:username, :min => 7)

validation_block do # Will only get called if previous validation passed
  validate_uniqueness(:username) do |username|
    User.where(:username => username).empty?
  end
end
```

Extensions
----------

These forms were meant to be extended when necessary. These are a few examples
of how they can be extended.

### Extensions::Paginate

An extension to paginate results with Sequel Datasets.

```ruby
module Extensions
  module Presenter

    DEFAULT_PER_PAGE = 30
    MAX_PER_PAGE = 100

    def self.included(base)
      base.attribute(:page, :type => :integer, :skip_reader => true)
      base.attribute(:per_page, :type => :integer, :skip_reader => true)
    end

    def each(&block)
      results.each(&block)
    end

    def total_pages
      @total_pages ||= (1.0 * dataset.count / per_page).ceil
    end

    def any?
      total_pages > 0
    end

    def results
      @results ||= begin
        start = (page - 1) * per_page
        _dataset = dataset.limit(per_page, start)
        _dataset.all
      end
    end

    def per_page
      if @per_page && @per_page >= 1 && per_page <= MAX_PER_PAGE
        @per_page
      else
        DEFAULT_PER_PAGE
      end
    end

    def page
      @page && @page > 1 ? @page : 1
    end

  end
end

module Presenters
  class UserPets < Organ::Form

    include Extensions::Paginate

    attribute(:user_id, :type => :integer)

    def dataset
      Pet.where(:user_id => user_id)
    end

  end
end

# Sinatra app
get "/pets" do
  presenter = Presenter::UserPets.new({
    :user_id => session[:user_id],
    :page => params[:page],
    :per_page => params[:per_page]
  })
  erb(:"pets/index", :locals => { :pets => presenter })
end
```

### Extensions::Worker

An extension to create worker job handlers using
[Ost](https://github.com/soveran/ost).

```ruby
module Extensions
  module Worker

    def self.queue_job(attributes)
      queue << JSON.generate(attributes)
    end

    def self.stop
      queue.stop
    end

    def self.watch_queue
      queue.each do |json_str|
        attributes = JSON.parse(json_str)
        new(attributes).perform
      end
    end

    private

    def self.queue
      Ost[self.name]
    end

  end
end

module Workers
  class EmailNotifier < Organ::Form

    include Extensions::Worker

    attribute(:email)
    attribute(:message)

    def perform
      # send message to email...
    end

  end
end

# Sinatra app
get "/queue_email" do
  Workers::EmailNotifier.queue_job(params[:notification])
  status(204)
end
```

Aknowledgements
---------------

This library was inspired mainly by @soveran
[Scrivener](https://github.com/soveran/scrivener) and was made with the help ofn
@grilix.
