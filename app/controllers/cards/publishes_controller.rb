class Cards::PublishesController < ApplicationController
  include CardScoped

  def create
    @card.publish

    if add_another_param?
      next_card = create_draft_card_with_retry
      redirect_to card_draft_path(next_card), notice: "Card added"
    else
      redirect_to @card.board
    end
  end

  private
    def add_another_param?
      params[:creation_type] == "add_another"
    end

    def create_draft_card_with_retry(max_attempts: 3)
      attempts = 0

      begin
        attempts += 1
        @board.cards.create!(status: "drafted")
      rescue ActiveRecord::RecordNotUnique => e
        if attempts < max_attempts
          retry
        else
          raise
        end
      end
    end
end
