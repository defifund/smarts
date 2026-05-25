require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Selenium talks to the local ChromeDriver/Chrome endpoints on 127.0.0.1.
  # WebMock stays active for external calls, but localhost has to be open.
  WebMock.disable_net_connect!(allow_localhost: true)
end
