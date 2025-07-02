class AddNotNullToAccountsQueenbeeId < ActiveRecord::Migration[8.1]
  def change
    change_column_null :accounts, :queenbee_id, false
  end
end
