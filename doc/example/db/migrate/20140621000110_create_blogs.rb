class CreateBlogs < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.string  :name
      t.text    :description
      t.integer :company_id
    end
  end
end
