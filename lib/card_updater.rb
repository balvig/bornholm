class CardUpdater
  def initialize(payload)
    @payload = payload
  end

  def run
    return unless payload.pull_request?

    case
    when closed?
      update_cards(:accept)
    when !wip?
      update_cards(:finish)
    end

    if opened?
      attach_to_cards
    end
  end

  private

    attr_reader :payload

    def opened?
      payload.action == "opened"
    end

    def closed?
      issue.closed?
    end

    def wip?
      issue.wip?
    end

    def issue
      payload.issue
    end

    def attach_to_cards
      card_ids.each do |id|
        trello.attach(id, url: issue.html_url)
      end
    end

    def update_cards(status)
      card_ids.each do |id|
        trello.update_card(id, status: status)
      end
    end

    def card_ids
      issue.card_ids
    end

    def trello
      Cp8.trello_client
    end
end
