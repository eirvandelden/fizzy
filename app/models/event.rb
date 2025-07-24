class Event < ApplicationRecord
  include Notifiable, Particulars, Promptable

  belongs_to :collection
  belongs_to :creator, class_name: "User"
  belongs_to :eventable, polymorphic: true

  scope :chronologically, -> { order created_at: :asc, id: :desc }

  after_create -> { eventable.event_was_created(self) }

  delegate :card, to: :eventable

  def action
    super.inquiry
  end

  def notifiable_target
    eventable
  end
end
