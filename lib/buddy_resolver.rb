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
    delegate :login, to: :user

    def buddies
      buddy_logins.map do |login|
        User.new(login: login)
      end
    end

    def buddy_logins
      member_logins.without(login)
    end

    def member_logins
      find_member_logins || []
    end

    def find_member_logins
      mappings.find do |members|
        members.map(&:downcase).find do |member|
          member == login
        end
      end
    end
end
