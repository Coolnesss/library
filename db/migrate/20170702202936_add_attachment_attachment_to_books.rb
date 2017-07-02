class AddAttachmentAttachmentToBooks < ActiveRecord::Migration
  def self.up
    change_table :books do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :books, :attachment
  end
end
