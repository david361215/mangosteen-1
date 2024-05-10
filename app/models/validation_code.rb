class ValidationCode < ApplicationRecord
  #email 必填
  validates :email, presence: true
end