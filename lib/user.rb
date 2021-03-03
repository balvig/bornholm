require "yaml"
require "buddy_resolver"

class User
  MAPPINGS = YAML::load_file(File.join(__dir__, "user_mappings.yml")).transform_keys(&:downcase)
  attr_reader :login

  def self.from_resource(resource)
    new(**resource.to_h)
  end

  def initialize(login:, avatar_url: nil, type: "User", **other)
    @login = login.downcase
    @avatar_url = avatar_url
    @type = type
  end

  def chat_name
    "<@#{mapped_login}>"
  end

  def avatar_url(size: 16)
    @avatar_url + "&size=#{size}"
  end

  def bot?
    type == "Bot"
  end

  def ==(other)
    return unless other.is_a?(User)
    login == other.login
  end

  alias :eql? :==

  def hash
    login.hash
  end

  private

    attr_reader :type

    def mapped_login
      MAPPINGS[login] || login
    end
end
