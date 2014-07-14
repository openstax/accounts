class Supergroup < ActiveRecord::Base
  belongs_to :application
  attr_accessible :name
end
