json.(reaction, :id, :content)
json.reacter do
  json.partial! "users/user", user: reaction.reacter
end
json.url card_comment_reaction_url(reaction.comment.card, reaction.comment, reaction)
