class BubblesController < ApplicationController
  include ProjectScoped

  before_action :set_bubble, only: %i[ show edit update ]

  def index
    if params[:tag_id]
      @tag = Tag.find(params[:tag_id])
      @bubbles = @tag.bubbles
      @most_active_bubbles = @tag.bubbles.left_joins(:comments, :boosts).group(:id).order(Arel.sql("COUNT(comments.id) + COUNT(boosts.id) DESC")).limit(10)
    else
      @bubbles = @project.bubbles.order(created_at: :desc)
      @most_active_bubbles = @project.bubbles.left_joins(:comments, :boosts).group(:id).order(Arel.sql("COUNT(comments.id) + COUNT(boosts.id) DESC")).limit(10)
    end
  end

  def new
    @bubble = @project.bubbles.build
  end

  def create
    @bubble = @project.bubbles.create!(bubble_params)
    redirect_to project_bubble_url(@project, @bubble)
  end

  def show
  end

  def edit
  end

  def update
    @bubble.update!(bubble_params)
    redirect_to project_bubble_url(@project, @bubble)
  end


  private
    def set_bubble
      @bubble = @project.bubbles.find(params[:id])
    end

    def bubble_params
      params.require(:bubble).permit(:title, :color, :due_on, :image, tag_ids: [])
    end
end
