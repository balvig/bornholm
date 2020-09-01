require "yaml"

class BuddyResolver
  cattr_accessor :mappings do
    YAML::load_file(File.join(__dir__, "buddy_mappings.yml"))
  end

  def initialize(user)
    @user = user
  end

  def buddy
    buddies.first
  end

  private

    attr_reader :user

    def buddies
      members.without(user)
    end

    def members
      find_members || []
    end

    def mapped_users
      mappings.map do |logins|
        logins.map do |login|
          User.new(login: login)
        end
      end
    end

    def find_members
      mapped_users.find do |members|
        members.find do |member|
          member == user
        end
      end
    end
end
