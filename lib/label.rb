class Label
  COLORS = {
    Icebox: "eb6420",
    WIP: "5319e7"
  }

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def add_to(issue)
    return if added_to_issue?(issue)

    ensure_label_exists(issue.repo)
    github.add_labels_to_an_issue(issue.repo, issue.number, [name])
  end

  def remove_from(issue)
    return unless added_to_issue?(issue)

    github.remove_label(issue.repo, issue.number, name)
  end

  private

    def added_to_issue?(issue)
      github.labels_for_issue(issue.repo, issue.number).map(&:name).include?(name.to_s)
    end

    def ensure_label_exists(repo)
      github.label(repo, name)
    rescue Octokit::NotFound
      github.add_label(repo, name, color)
    end

    def color
      COLORS[name]
    end

    def github
      Cp8.github_client
    end
end
