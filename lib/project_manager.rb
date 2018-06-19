class ProjectManager
  def initialize(issue:, project_column_id: nil)
    @issue = issue
    @project_column_id = project_column_id
  end

  def run
    return "Project manager not configured, skipping." if project_column_id.blank?

    add_to_project
  end

  private

    attr_reader :issue, :project_column_id

    def add_to_project
      github.create_project_card(project_column_id, content_id: issue.id, content_type: "Issue")
      "Card created."
    rescue Octokit::NotFound
      "Could not find column with id #{project_column_id}."
    rescue Octokit::Unauthorized
      "Could not find column with id #{project_column_id} in this project."
    end

    def github
      Cp8.github_client
    end
end
