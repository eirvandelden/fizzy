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

      next_card.reload

      respond_to do |format|
        format.html { redirect_to next_card, notice: "Card added" }
        format.turbo_stream { redirect_to next_card, notice: "Card added" }
      end
    else
      respond_to do |format|
        format.html { redirect_to @card.board }
        format.turbo_stream { redirect_to @card.board }
      end
    end
  end

  private
    def add_another_param?
      params[:creation_type] == "add_another"
    end
end
