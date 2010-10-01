class Favorite
  include MongoMapper::Document

  key :_id, String
  key :group_id, String, :index => true
  belongs_to :group

  key :user_id, String, :index => true
  belongs_to :user

  key :question_id, String
  belongs_to :question

  key :discussion_id, String
  belongs_to :discussion

  key :bookmark_id, String
  belongs_to :bookmark

  validate :should_be_unique # FIXME

  protected
  def should_be_unique
    favorite = Favorite.first({:question_id => self.question_id,
                               :discussion_id => self.discussion_id,
                               :bookmark_id => self.bookmark_id,
                               :user_id     => self.user_id,
                               :group_id    => self.group_id
                              })

    valid = (favorite.nil? || favorite.id == self.id)
    if !valid
      self.errors.add(:favorite, "You already marked this item")
    end
  end
end
