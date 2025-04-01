require 'vcr'
require 'webmock'

class VCRHelper
  def self.mock_connection_error
    WebMock.disable_net_connect!(allow_localhost: true)

    WebMock::API.stub_request(:any, /api.pexels.com/).to_timeout
    yield
  ensure
    WebMock.allow_net_connect!
  end
end
