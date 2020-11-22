class AddAttachmentAttachmentToBooks < ActiveRecord::Migration[4.2]
  def self.up
    change_table :books do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :books, :attachment
  end
end
