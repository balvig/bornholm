class ProjectManager
  def initialize(issue:, project_column_id: nil)
    @issue = issue
    @project_column_id = project_column_id
  end

  def run
    return unless project_column_id && !belongs_to_project?
    
    add_to_project
  end

  private

    attr_reader :issue, :project_column_id

    def belongs_to_project?
      github.column_cards(project_column_id).map(&:content_url).include?(issue.html_url)
    end

    def add_to_project
      github.create_project_card(project_column_id, content_id: issue.number, content_type: 'Issue')
    end

    def github
      Cp8.github_client
    end

end
