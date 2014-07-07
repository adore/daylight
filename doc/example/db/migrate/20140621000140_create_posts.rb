class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string   :title
      t.string   :slug
      t.text     :body
      t.datetime :published_at
      t.datetime :edited_at
      t.integer  :view_count, default: 0
      t.integer  :blog_id
      t.integer  :author_id
    end
  end
end
