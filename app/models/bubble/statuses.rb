module Bubble::Statuses
  extend ActiveSupport::Concern

  included do
    enum :status, %w[ creating drafted published ].index_by(&:itself)

    scope :published_or_drafted_by, ->(user) { where(status: :published).or(where(status: :drafted, creator: user)) }
  end

  class_methods do
    def recently_abandoned_creation(user)
      creating.where(creator: user).where("created_at != updated_at").where(updated_at: 1.day.ago..).last
    end

    def recover_recently_abandoned_creation(user)
      recently_abandoned_creation(user).tap do |bubble|
        creating.where(creator: user).excluding(bubble).destroy_all
      end
    end
  end

  def publish
    transaction do
      published!
      track_event :published

      if assignments.any?
        track_event :assigned, assignee_ids: assignee_ids
      end
    end
  end
end
