class RemoveBoardCreatorDraftedIndexFromCards < ActiveRecord::Migration[8.2]
  def up
    remove_index :cards, name: "index_cards_on_board_creator_drafted", if_exists: true
  end
end
