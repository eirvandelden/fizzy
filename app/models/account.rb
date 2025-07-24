class Account < ApplicationRecord
  include Entropic, Joinable, SignalAccount

  has_many_attached :uploads

  class << self
    def script_name
      @script_name ||= "/#{sole.queenbee_id}"
    end
  end

  def setup_basic_template
    user = User.first

    Closure::Reason.create_defaults
    Collection.create!(name: "Cards", creator: user, all_access: true)
    workflow = Workflow.create!(name: "Basic")
    Collection.first.update!(workflow: workflow)
  end
end
