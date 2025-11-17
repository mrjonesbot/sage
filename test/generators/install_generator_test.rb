require "test_helper"
require "generators/sage/install/install_generator"

class InstallGeneratorTest < ActiveSupport::TestCase
  test "pagy initializer works with frozen Pagy::DEFAULT (both 9.x and 43.x)" do
    pagy_initializer_path = File.expand_path("../../config/initializers/pagy.rb", __dir__)

    assert File.exist?(pagy_initializer_path), "Pagy initializer should exist"

    require "pagy"

    # Simulate Rails 8.1.1 / Ruby 3.4.4 environment where Pagy::DEFAULT is frozen
    original_default = Pagy::DEFAULT.dup
    Pagy.send(:remove_const, :DEFAULT)
    Pagy.const_set(:DEFAULT, original_default.freeze)

    # This should NOT raise an error - the initializer should handle frozen hash
    assert_nothing_raised do
      load pagy_initializer_path
    end

    # Verify the initializer works with both Pagy versions
    pagy_version = Pagy::VERSION.to_i
    if pagy_version >= 43
      assert Pagy::DEFAULT.key?(:limit), "Pagy 43.x should have :limit key"
    else
      assert Pagy::DEFAULT.key?(:items) || Pagy::DEFAULT.key?(:limit), "Pagy 9.x should have :items or :limit key"
    end

    assert true, "Pagy initializer loaded successfully with frozen Pagy::DEFAULT"

  ensure
    # Restore original state
    if defined?(Pagy)
      Pagy.send(:remove_const, :DEFAULT) if Pagy.const_defined?(:DEFAULT)
      Pagy.const_set(:DEFAULT, original_default)
    end
  end
end
