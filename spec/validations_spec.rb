require_relative "spec_helper"

describe Organ::Validations do
  let(:new_errors) { [] }
  let(:username_value) { nil }
  let(:validator) do
    Module.new do
      extend Organ::Validations

      def self.validate
      end
    end
  end

  before do
    value = username_value
    validator.define_singleton_method(:username) { value }
  end

  describe "#errors" do
    it "returns an empty hash" do
      errors = validator.errors
      assert(errors.empty?)
    end
  end

  describe "#valid?" do
    describe "when no errors added on #validate" do
      it "is valid" do
        assert(validator.valid?)
      end
    end

    describe "when errors added on #validate" do
      it "is not valid" do
        def validator.validate
          append_error(:username, :invalid)
        end
        refute(validator.valid?)
      end
    end
  end

  describe "#append_error" do
    it "appends an error to the attribute" do
      validator.append_error(:username, :invalid)
      assert_equal(1, validator.errors[:username].size)
    end
  end

  describe "#validate_presence" do
    describe "when attribute has nil value" do
      it "appends a :blank error" do
        validator.validate_presence(:username)
        assert_includes(validator.errors[:username], :blank)
        assert_equal(1, validator.errors[:username].size)
      end
    end

    describe "when attribute has empty string value" do
      let(:username_value) { "" }

      it "appends a :blank error" do
        validator.validate_presence(:username)
        assert_includes(validator.errors[:username], :blank)
        assert_equal(1, validator.errors[:username].size)
      end
    end
  end

  describe "#validate_uniqueness" do
    describe "when block returns false" do
      describe "when value is not present" do
        let(:username_value) { nil }

        it "doesn't append any error" do
          validator.validate_uniqueness(:username) { |u| false }

          assert_equal(0, validator.errors[:username].size)
        end
      end

      describe "when value is present" do
        let(:username_value) { "username" }

        it "appends a :taken error" do
          validator.validate_uniqueness(:username) { |u| false }
          assert_includes(validator.errors[:username], :taken)
          assert_equal(1, validator.errors[:username].size)
        end
      end
    end
  end

  describe "#validate_email_format" do
    describe "when value is not an email" do
      describe "when value is not present" do
        let(:username_value) { nil }

        it "doesn't append any error" do
          validator.validate_email_format(:username)

          assert_equal(0, validator.errors[:username].size)
        end
      end

      describe "when value is present" do
        let(:username_value) { "not.an@email" }

        it "appends an :invalid error" do
          validator.validate_email_format(:username)
          assert_includes(validator.errors[:username], :invalid)
          assert_equal(1, validator.errors[:username].size)
        end
      end
    end
  end

  describe "#validate_format" do
    describe "when value does not match the regexp" do
      describe "when value is not present" do
        let(:username_value) { nil }

        it "doesn't append any error" do
          validator.validate_format(:username, /\A[a-z]+\Z/)

          assert_equal(0, validator.errors[:username].size)
        end
      end

      describe "when value is present" do
        let(:username_value) { "ema8l" }

        it "appends an :invalid error" do
          validator.validate_format(:username, /\A[a-z]+\Z/)
          assert_includes(validator.errors[:username], :invalid)
          assert_equal(1, validator.errors[:username].size)
        end
      end
    end
  end

  describe "#validate_length" do
    describe "when value size is less than the min" do
      describe "when value is not present" do
        let(:username_value) { nil }

        it "doesn't append any error" do
          validator.validate_length(:username, :min => 8)

          assert_equal(0, validator.errors[:username].size)
        end
      end

      describe "when value is present" do
        let(:username_value) { "ema8l" }

        it "appends a :too_short error" do
          validator.validate_length(:username, :min => 8)
          assert_includes(validator.errors[:username], :too_short)
          assert_equal(1, validator.errors[:username].size)
        end
      end
    end

    describe "when value size is greater than the max" do
      let(:username_value) { "ema8l" }

      it "appends a :too_long error" do
        validator.validate_length(:username, :max => 2)
        assert_includes(validator.errors[:username], :too_long)
        assert_equal(1, validator.errors[:username].size)
      end
    end
  end

  describe "#validate_inclusion" do
    describe "when is not included in the list" do
      describe "when value is not present" do
        let(:username_value) { nil }

        it "doesn't append any error" do
          validator.validate_inclusion(:username, [2, 3])

          assert_equal(0, validator.errors[:username].size)
        end
      end

      describe "when value is present" do
        let(:username_value) { 1 }

        it "appends a :not_included error" do
          validator.validate_inclusion(:username, [2, 3])
          assert_includes(validator.errors[:username], :not_included)
          assert_equal(1, validator.errors[:username].size)
        end
      end
    end
  end

  describe "#validate_range" do
    describe "when value is less than the min" do
      describe "when value is not present" do
        let(:username_value) { nil }

        it "doesn't append any error" do
          validator.validate_range(:username, :min => 8)

          assert_equal(0, validator.errors[:username].size)
        end
      end

      describe "when value is present" do
        let(:username_value) { 5 }

        it "appends a :less_than error" do
          validator.validate_range(:username, :min => 8)
          assert_includes(validator.errors[:username], :less_than)
          assert_equal(1, validator.errors[:username].size)
        end
      end
    end

    describe "when value is greater than the max" do
      let(:username_value) { 5 }

      it "appends a :greater_than error" do
        validator.validate_range(:username, :max => 3)
        assert_includes(validator.errors[:username], :greater_than)
        assert_equal(1, validator.errors[:username].size)
      end
    end
  end

  describe "#validation_block" do
    describe "when form has no errors" do
      let(:username_value) { "validusername" }

      it "calls the given block" do
        validator.validate_presence(:username)

        block_called = 0

        validator.validation_block do
          block_called += 1
        end

        assert_equal(1, block_called)
      end
    end

    describe "when form has errors" do
      it "doesn't call the given block" do
        validator.validate_presence(:username)

        block_called = 0

        validator.validation_block do
          block_called += 1
        end

        assert_equal(0, block_called)
      end
    end
  end

end
