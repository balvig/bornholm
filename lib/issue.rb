require "active_support/core_ext/array"
require "issue_title"
require "user"

class Issue
  attr_reader :id, :number, :html_url, :repo, :title, :body

  def initialize(id:, number:, repo:, title: nil, body: nil, state: nil, draft: false, html_url: nil, user: nil, **other)
    @id = id
    @number = number
    @repo = repo
    @title = IssueTitle.new(title)
    @body = body
    @state = state
    @draft = draft
    @html_url = html_url
    @user_resource = user
  end

  def wip?
    title.tags.include?(:wip)
  end

  def draft?
    !!@draft
  end

  def draft_or_wip?
    draft? || wip?
  end

  def closed?
    state == "closed"
  end

  def peer_reviewers
    reviewers.without(user, *User.bots)
  end

  def requested_reviewers
    github.pull_request_review_requests(repo, number).users.map do |resource|
      User.from_resource(resource)
    end
  end

  def user
    return unless user_resource

    User.from_resource(user_resource)
  end

  def additions
    extended_pr_data[:additions]
  end

  def deletions
    extended_pr_data[:deletions]
  end

  private

    attr_reader :state, :user_resource

    def reviewers
      reviews.map(&:user).map do |resource|
        User.from_resource(resource)
      end.uniq
    end

    def reviews
      github.pull_request_reviews(repo, number)
    rescue Octokit::NotFound
      []
    end

    def extended_pr_data
      @_extended_data ||= fetch_extended_pr_data
    end

    def fetch_extended_pr_data
      github.pull_request(repo, number)
    rescue Octokit::NotFound
      {}
    end

    def github
      Cp8.github_client
    end
end
