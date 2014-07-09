class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string   :name
      t.text     :content
      t.boolean  :spam
      t.datetime :published_at
      t.datetime :edited_at
      t.integer  :like_count
      t.integer  :post_id
      t.integer  :commenter_id
    end
  end
end
