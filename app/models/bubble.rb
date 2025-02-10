class Bubble < ApplicationRecord
  include Assignable, Boostable, Colored, Commentable, Eventable,
    Messages, Notifiable, Poppable, Searchable, Staged, Statuses, Taggable

  belongs_to :bucket, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_many :notifications, dependent: :destroy

  has_one_attached :image, dependent: :purge_later

  after_save :track_due_date_change, if: :saved_change_to_due_on?
  after_save :track_title_change, if: :saved_change_to_title?

  scope :reverse_chronologically, -> { order created_at: :desc, id: :desc }
  scope :chronologically, -> { order created_at: :asc, id: :asc }
  scope :ordered_by_activity, -> { order activity_score: :desc }
  scope :in_bucket, ->(bucket) { where bucket: bucket }

  scope :indexed_by, ->(index) do
    case index
    when "most_active"    then ordered_by_activity
    when "most_discussed" then ordered_by_comments
    when "most_boosted"   then ordered_by_boosts
    when "newest"         then reverse_chronologically
    when "oldest"         then chronologically
    when "popped"         then popped
    end
  end

  def rescore
    update! activity_score: boosts_count + comments_count
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
        track_event("title_changed", particulars: {
          old_title: title_before_last_save,
          new_title: title
        })
      end
    end
end
