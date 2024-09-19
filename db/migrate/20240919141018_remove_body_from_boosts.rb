class RemoveBodyFromBoosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :boosts, :body, :string
  end
end
