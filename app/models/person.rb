class Person < ActiveRecord::Base
  has_many :users, dependent: :destroy, inverse_of: :person
end
