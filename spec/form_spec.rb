require_relative "spec_helper"

describe Organ::Form do

  describe ".attribute" do
    it "defines an attribute reader" do
      form_klass = Class.new(Organ::Form) do
        attribute(:username)
      end
      form = form_klass.new(:username => "user")

      assert_equal("user", form.username)
    end

    describe "if :skip_reader option is true" do
      it "doesn't define an attribute reader" do
        form_klass = Class.new(Organ::Form) do
          attribute(:username, :skip_reader => true)
        end
        form = form_klass.new(:username => "user")

        refute(form.respond_to?(:username))
      end
    end

    describe "if type is given" do
      it "coerces the value" do
        form_klass = Class.new(Organ::Form) do
          attribute(:username, :type => :fruit)

          def coerce_fruit(value, options = {})
            "apple"
          end
        end
        form = form_klass.new(:username => "user")

        assert_equal("apple", form.username)
      end
    end
  end

  describe "#set_attributes" do
    form_klass = Class.new(Organ::Form) do
      attribute(:username)
      attribute(:password)
    end

    it "sets all attributes given" do
      form = form_klass.new
      form.set_attributes(:username => "user")

      assert_equal("user", form.username)
      assert_nil(form.password)
    end
  end

  describe "#attributes" do
    form_klass = Class.new(Organ::Form) do
      attribute(:username)
      attribute(:password)
    end

    it "retrieves all form attributes" do
      form = form_klass.new(:username => "user")
      attributes = form.attributes

      assert_equal(2, attributes.size)
      assert_includes(attributes, :username)
      assert_includes(attributes, :password)
    end

  end

  describe "#perform!" do
    let(:form_klass) do
      Class.new(Organ::Form) do
        attribute(:username)
        attribute(:password)

        def validate
        end

        def perform
        end
      end
    end

    let(:form) { form_klass.new }

    describe "if no errors during validate or perform" do
      it "doesn't raise any exceptions" do
        form.perform!
        assert(true)
      end
    end

    describe "if any errors on validate" do
      it "raises an error" do
        def form.validate
          append_error(:username, :invalid)
        end

        assert_raises(Organ::ValidationError) do
          form.perform!
        end
      end
    end

    describe "if any errors on perform" do
      it "raises an error" do
        def form.perform
          append_error(:username, :invalid)
        end

        assert_raises(Organ::ValidationError) do
          form.perform!
        end
      end
    end

  end
end
