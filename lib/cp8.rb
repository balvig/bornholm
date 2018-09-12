require "dotenv/load"
require "octokit"
require "slack-notifier"

require "payload"
require "processor"
require "silent_chat_client"

class Cp8
  DEFAULT_CHAT_USER = "CP-8"

  class << self
    attr_writer :github_client, :chat_client

    def github_client
      @github_client
    end

    def chat_client
      @chat_client || slack || silence
    end

    private

      def slack
        return unless ENV["SLACK_WEBHOOK_URL"]
        @_slack ||= build_slack
      end

      def build_slack
        Slack::Notifier.new(
          ENV["SLACK_WEBHOOK_URL"],
          username: DEFAULT_CHAT_USER
        )
      end

      def silence
        @_silence ||= SilentChatClient.new
      end
  end
end
