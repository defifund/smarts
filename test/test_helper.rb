ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

module SilenceEthFrozenStringWarnings
  def warn(message, category: nil, **)
    return if message.is_a?(String) &&
              message.include?("gems/eth-") &&
              message.include?("literal string will be frozen")
    super
  end
end
Warning.singleton_class.prepend(SilenceEthFrozenStringWarnings)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Minitest 6 dropped Minitest::Mock#stub. Block-scoped singleton-method
    # replacement: stub_impl is a callable (lambda/proc), yielded block runs the test.
    def stub_class_method(receiver, method_name, stub_impl)
      original = receiver.method(method_name)
      receiver.define_singleton_method(method_name) do |*a, **kw, &b|
        stub_impl.call(*a, **kw, &b)
      end
      yield
    ensure
      receiver.define_singleton_method(method_name, original)
    end
  end
end
