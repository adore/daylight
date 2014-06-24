class User < ActiveRecord::Base
  has_many :blogs
  has_many :posts, foreign_key: "author"
  has_many :comments, foreign_key: "commenter"
end
