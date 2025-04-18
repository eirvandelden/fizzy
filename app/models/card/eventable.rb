module Card::Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, dependent: :destroy

    before_create { self.last_active_at = Time.current }

    after_save :track_due_date_change, if: :saved_change_to_due_on?
    after_save :track_title_change, if: :saved_change_to_title?
  end

  def track_event(action, creator: Current.user, **particulars)
    if published?
      event = find_or_capture_event_summary.events.create! action: action, creator: creator, card: self, particulars: particulars
      event.generate_notifications_later
    end
  end

  private
    def track_due_date_change
      if due_on.present?
        if due_on_before_last_save.nil?
          track_event("due_date_added", particulars: { due_date: due_on })
        else
          track_event("due_date_changed", particulars: { due_date: due_on })
        end
      elsif due_on_before_last_save.present?
        track_event("due_date_removed")
      end
    end

    def track_title_change
      if title_before_last_save.present?
        track_event "title_changed", particulars: { old_title: title_before_last_save, new_title: title }
      end
    end

    def find_or_capture_event_summary
      transaction do
        messages.last&.event_summary || capture(EventSummary.new).event_summary
      end
    end
end
