# Automatically use UUID type for all binary(16) columns

module MysqlUuidAdapter
  extend ActiveSupport::Concern

  # Override lookup_cast_type to recognize binary(16) as UUID type
  def lookup_cast_type(sql_type)
    if sql_type == "binary(16)"
      ActiveRecord::Type.lookup(:uuid, adapter: :trilogy)
    else
      super
    end
  end

  class_methods do
    def native_database_types
      @native_database_types_with_uuid ||= super.merge(uuid: { name: "binary", limit: 16 })
    end
  end
end

module SqliteUuidAdapter
  extend ActiveSupport::Concern

  # Override lookup_cast_type to recognize BLOB as UUID type
  def lookup_cast_type(sql_type)
    if sql_type == "blob(16)"
      ActiveRecord::Type.lookup(:uuid, adapter: :sqlite3)
    else
      super
    end
  end

  # Override fetch_type_metadata to preserve UUID type and limit
  def fetch_type_metadata(sql_type)
    if sql_type == "blob(16)"
      ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
        sql_type: sql_type,
        type: :uuid,
        limit: 16
      )
    else
      super
    end
  end

  class_methods do
    def native_database_types
      @native_database_types_with_uuid ||= super.merge(uuid: { name: "blob", limit: 16 })
    end
  end
end

module SchemaDumperUuidType
  # Map binary(16) and blob(16) columns to :uuid type in schema.rb
  def schema_type(column)
    if column.sql_type == "binary(16)" || column.sql_type == "blob(16)"
      :uuid
    else
      super
    end
  end
end

module TableDefinitionUuidSupport
  def uuid(name, **options)
    column(name, :uuid, **options)
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::TableDefinition.prepend(TableDefinitionUuidSupport)
end

ActiveSupport.on_load(:active_record_trilogyadapter) do
  ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend(MysqlUuidAdapter)
  ActiveRecord::ConnectionAdapters::MySQL::SchemaDumper.prepend(SchemaDumperUuidType)
end

ActiveSupport.on_load(:active_record_sqlite3adapter) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(SqliteUuidAdapter)
  ActiveRecord::ConnectionAdapters::SQLite3::SchemaDumper.prepend(SchemaDumperUuidType)
end
