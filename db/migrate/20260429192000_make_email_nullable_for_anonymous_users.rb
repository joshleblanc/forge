class MakeEmailNullableForAnonymousUsers < ActiveRecord::Migration[8.1]
  def up
    change_column_null :users, :email, true
  end

  def down
    # Only make non-null where email is not present (anonymous users)
    User.where(email: nil).update_all(email: "anonymous_placeholder")
    change_column_null :users, :email, false
  end
end