class UpdateSettingsValueToStudentFlow < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.connection.execute("delete from Settings where var = 'newflow_feature_flag'")
  end

  def down
  end
end
