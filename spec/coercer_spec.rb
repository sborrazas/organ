require_relative "spec_helper"

describe Organ::Coercer do
  let(:coercer) do
    Module.new do
      extend Organ::Coercer
    end
  end

  describe "#coerce_string" do
    describe "when value is truthy" do
      it "returns a string" do
        assert_equal("truthy!", coercer.coerce_string("truthy!"))
      end
    end

    describe "when value is falsy" do
      it "returns nil" do
        assert_nil(coercer.coerce_string(false))
      end
    end

    describe "when sending a :trim option to true" do
      it "returns a string with no trailing spaces" do
        result = coercer.coerce_string("  \n truthy  ! \n ", :trim => true)
        assert_equal("truthy !", result)
      end
    end
  end

  describe "#coerce_boolean" do
    describe "when value is truthy" do
      it "returns true" do
        assert_equal(true, coercer.coerce_boolean("truthy"))
      end
    end

    describe "when value is falsy" do
      it "returns false" do
        assert_equal(false, coercer.coerce_boolean(nil))
      end
    end
  end

  describe "#coerce_array" do
    describe "when value is an array" do
      describe "when no :element_type option is given" do
        it "returns the array" do
          value = ["1", "2", "3"]
          assert_equal(value, coercer.coerce_array(value))
        end
      end

      describe "when :element_type option is given" do
        it "coerces the elements inside" do
          value = ["1", "2", "3"]
          result = coercer.coerce_array(value, :element_type => :integer)
          assert_equal([1, 2, 3], result)
        end
      end
    end

    describe "when value is a hash" do
      it "returns its values" do
        value = { "1" => 2, "2" => 4 }
        result = coercer.coerce_array(value)
        assert_includes(result, 2)
        assert_includes(result, 4)
      end
    end

    describe "when value is not an array or a hash" do
      it "returns an empty array" do
        assert_equal([], coercer.coerce_array(nil))
      end
    end
  end

  describe "#coerce_float" do
    describe "when value doesn't have a float format" do
      it "returns nil" do
        assert_nil(coercer.coerce_float("nope"))
      end
    end

    describe "when has a float format" do
      it "returns a float" do
        values = {
          ".99" => 0.99,
          "12.3456" => 12.3456,
          "5" => 5.0
        }
        values.each do |value, expected|
          assert_equal(expected, coercer.coerce_float(value))
        end
      end
    end
  end

  describe "#coerce_date" do
    describe "when value doesn't have a date format" do
      it "returns nil" do
        assert_nil(coercer.coerce_date("not a date"))
      end
    end

    describe "when value has a date format" do
      it "returns a date" do
        assert_equal(Date.civil(2014, 9, 28), coercer.coerce_date("2014-09-28"))
      end
    end
  end

end
