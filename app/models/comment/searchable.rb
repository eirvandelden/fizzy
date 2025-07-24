module Comment::Searchable
  extend ActiveSupport::Concern

  included do
    include ::Searchable
  end

  def search_embedding_content
    <<~CONTENT
        Card title: #{card.title}
        Content: #{body.to_plain_text}
        Created by: #{creator.name}}
      CONTENT
  end
end
