class Language < ApplicationRecord
	# Validations
	validates :name_en, length: { in: 3..20 }
	validates :name_es, length: { in: 3..20 }
	
	# Associations
	has_and_belongs_to_many :profile_models
	has_and_belongs_to_many :profile_photographers
	has_and_belongs_to_many :profile_contractors

	def name
		case I18n.locale
		when "en".to_sym
			return self.name_en
		when "es".to_sym
			return self.name_es
		end
	end
end
