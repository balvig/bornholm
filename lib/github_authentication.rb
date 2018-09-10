require "jwt"

class GithubAuthentication
  def initialize(payload)
    @payload = payload
  end

  def client
    Octokit::Client.new(bearer_token: installation_token)
  end

  private

    attr_reader :payload

    GITHUB_APP_IDENTIFIER = ENV["GITHUB_APP_IDENTIFIER"] || raise("GITHUB_GITHUB_APP_IDENTIFIER needs to be set")
    GITHUB_PRIVATE_KEY = ENV["GITHUB_PRIVATE_KEY"] || raise("GITHUB_PRIVATE_KEY needs to be set")
    ENCODED_PRIVATE_KEY = OpenSSL::PKey::RSA.new GITHUB_PRIVATE_KEY.gsub('\n', "\n") # convert newlines

    def installation_token
      app_client.create_installation_access_token(payload.installation_id)[:token]
    end

    def app_client
      Octokit::Client.new(bearer_token: jwt)
    end

    def jwt
      JWT.encode(jwt_payload, ENCODED_PRIVATE_KEY, "RS256")
    end

    def jwt_payload
      {
        iat: Time.now.to_i,
        exp: Time.now.to_i + (10 * 60),
        iss: GITHUB_APP_IDENTIFIER
      }
    end
end
