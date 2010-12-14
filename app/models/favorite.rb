class Favorite
  include MongoMapper::Document

  key :_id, String
  key :group_id, String, :index => true
  belongs_to :group

  key :user_id, String, :index => true
  belongs_to :user

  key :item_id, String
  belongs_to :item

  validate :should_be_unique # FIXME

  protected
  def should_be_unique
    favorite = Favorite.first({:item_id     => self.item_id,
                               :user_id     => self.user_id,
                               :group_id    => self.group_id
                              })

    valid = (favorite.nil? || favorite.id == self.id)
    if !valid
      self.errors.add(:favorite, "You already marked this item")
    end
  end
end
