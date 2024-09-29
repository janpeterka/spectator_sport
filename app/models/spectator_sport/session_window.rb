module SpectatorSport
  class SessionWindow < ApplicationRecord
    belongs_to :session
    has_many :events

    def analysis
      @analysis ||= SessionWindowAnalysis.new(self)
    end

    def events_before(event)
      events.where(id: ...event.id)
    end
  end
end
