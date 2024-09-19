class RemoveBodyFromBubbles < ActiveRecord::Migration[8.0]
  def change
    remove_column :bubbles, :body, :string
  end
end
