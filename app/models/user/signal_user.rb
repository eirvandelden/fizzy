module User::SignalUser
  extend ActiveSupport::Concern

  included do
    belongs_to :signal_user, dependent: :destroy, class_name: "SignalId::User", optional: true
  end
end
