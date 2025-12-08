class Cards::PublishesController < ApplicationController
  include CardScoped

  def create
    @card.publish

    if add_another_param?
      next_card = nil

      begin
        @board.account.with_lock do
          next_card = @board.cards.create!(status: "drafted")
        end
      rescue ActiveRecord::RecordNotUnique
        next_card = @board.cards.where(creator: Current.user, status: "drafted").order(created_at: :desc, id: :desc).first
        next_card ||= @board.cards.create!(status: "drafted")
      end

      redirect_to card_draft_path(next_card), notice: "Card added"
    else
      redirect_to @card.board
    end
  end

  private
    def add_another_param?
      params[:creation_type] == "add_another"
    end
end
