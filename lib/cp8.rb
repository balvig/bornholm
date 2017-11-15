require "payload"
require "processor"
require "trello"

class Cp8
  class << self
    attr_writer :trello_client, :github_client

    def trello_client
      @trello_client || trello_flow_api
    end

    def github_client
      @github_client || octokit
    end

    private

      def trello_flow_api
        raise "TRELLO_KEY and/or TRELLO_TOKEN env variables not set" unless ENV["TRELLO_KEY"] && ENV["TRELLO_TOKEN"]
        @_trello_client ||= Trello.new(key: ENV["TRELLO_KEY"], token: ENV["TRELLO_TOKEN"])
      end

      def octokit
        raise "OCTOKIT_ACCESS_TOKEN env variable not set" unless ENV["OCTOKIT_ACCESS_TOKEN"]
        @_octokit ||= Octokit::Client.new
      end
  end
end
