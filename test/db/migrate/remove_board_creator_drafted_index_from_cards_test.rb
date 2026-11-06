require "test_helper"

class RemoveBoardCreatorDraftedIndexFromCardsTest < ActiveSupport::TestCase
  INDEX_NAME = "index_cards_on_board_creator_drafted"

  test "does nothing when the drafted card index is absent" do
    assert_not drafted_card_index?

    assert_no_queries_match(/DROP INDEX/i, include_schema: true) { migrate_up }

    assert_not drafted_card_index?
  end

  if ActiveRecord::Base.connection_db_config.adapter == "sqlite3"
    test "removes the drafted card index when present" do
      add_drafted_card_index

      migrate_up

      assert_not drafted_card_index?
    end

    test "the drafted card index rejects moving a draft onto a board with another draft of its creator" do
      add_drafted_card_index
      draft = kevin_drafts_on_writebook_and_private

      error = assert_raises(ActiveRecord::RecordNotUnique) { draft.move_to(boards(:private)) }

      assert_match(/cards\.board_id, cards\.creator_id/, error.message)
    end

    test "a draft moves to a board where its creator already has a draft once the index is gone" do
      add_drafted_card_index
      draft = kevin_drafts_on_writebook_and_private
      migrate_up

      draft.move_to(boards(:private))

      assert_equal 2, boards(:private).cards.drafted.where(creator: users(:kevin)).count
    end
  end

  private
    def add_drafted_card_index
      connection.add_index :cards, [ :board_id, :creator_id ], unique: true, where: "status = 'drafted'", name: INDEX_NAME
    end

    def migrate_up
      migration = connection.pool.migration_context.migrations.find { it.name == "RemoveBoardCreatorDraftedIndexFromCards" }
      flunk "Migration RemoveBoardCreatorDraftedIndexFromCards is missing" unless migration

      ActiveRecord::Migration.suppress_messages { migration.migrate(:up) }
    end

    def drafted_card_index?
      connection.index_name_exists?(:cards, INDEX_NAME)
    end

    def kevin_drafts_on_writebook_and_private
      users(:kevin).draft_new_card_in(boards(:private))
      users(:kevin).draft_new_card_in(boards(:writebook))
    end

    def connection
      ActiveRecord::Base.connection
    end
end
