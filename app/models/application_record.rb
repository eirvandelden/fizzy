class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  configure_replica_connections

  attribute :id, :uuid, default: -> { ActiveRecord::Type::Uuid.generate }
end
