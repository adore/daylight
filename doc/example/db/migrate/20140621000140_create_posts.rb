class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string  :title
      t.text    :content
      t.integer :blog_id
    end
  end
end
