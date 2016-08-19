class Album < ApplicationRecord
  # Validations
  validates :name, length: { in: 3..20 }

  # Associatons
  belongs_to :profileable, polymorphic: true
  has_many :photos, as: :attachable, dependent: :destroy

  # Identifier
  after_save :set_identifier

  def set_identifier
  	self.identifier = self.id
  end
end
