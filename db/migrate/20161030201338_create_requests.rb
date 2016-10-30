class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.text :otp_request
      t.text :otp_response_body
      t.string :otp_response_code
      t.string :otp_response_message
      t.timestamps null: false
    end
  end
end
