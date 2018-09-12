lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "bundler"

Bundler.require :default, ENV["RACK_ENV"].to_sym

require "cp8"
require "github_authentication"

set :show_exceptions, false

post "/payload" do
  Cp8.github_client = authenticated_github_client
  Processor.new(payload, config: config).process
end

error 500 do
  error = env["sinatra.error"]
  "#{error.class}: #{error.message}"
end

private

  CP8_CONFIG_FILE = ".cp8.yml"

  def authenticated_github_client
    GithubAuthentication.new(payload).client
  end

  def payload
    request.body.rewind
    Payload.new_from_json(request.body.read)
  end

  def config
    fetch_config || {}
  end

  def fetch_config
    YAML.load config_file_contents
  rescue TypeError
  end

  def config_file_contents
    Base64.decode64 Cp8.github_client.contents(payload.repo, path: CP8_CONFIG_FILE).content
  rescue Octokit::NotFound
  end
