class ProfilePhotographer < ApplicationRecord
  	# Validations
	validates :first_name, length: { in: 3..20 }, allow_blank: true
	validates :last_name, length: { in: 3..20 }, allow_blank: true
	validates :mobile_phone, length: { in: 8..20 }, allow_blank: true
	validates :land_phone, length: { in: 8..20 }, allow_blank: true
	validates :address, length: { maximum: 100 }, allow_blank: true
	validates :gender, inclusion: { in: %w(Female Male) }, allow_blank: true

	# User
	has_one :user, as: :profileable

	# Nomenclators
	has_and_belongs_to_many :languages, dependent: :destroy
	belongs_to :current_province, class_name: "Province", foreign_key: "current_province_id", optional: true
	belongs_to :nationality, optional: true

	# Pictures
	has_many :albums, as: :profileable, dependent: :destroy
	has_many :photos, through: :albums

	# Inbox
	has_many :messages, -> { order "created_at DESC" }, as: :ownerable, dependent: :destroy

	# Studies
	has_many :studies, as: :ownerable, dependent: :destroy

	# Wallet
	has_one :wallet, as: :ownerable
	has_many :coupon_charges, through: :wallet

	# Plan
	belongs_to :plan

	#Check if profile is completed
	def profile_complete?
		parameters_with_values = generate_array_of_param_with_value

		parameters_with_values.each do |p|
			return false if !p
		end

		return true
	end

	def profile_complete_progress
		progress = 0
		parameters_with_values = generate_array_of_param_with_value

		progress = parameters_with_values.reject{ |p| !p }.length

		return progress
	end

	def profile_complete_progress_total
		total = 10
	end

	def profile_complete_progress_percentage
		progress = (profile_complete_progress * 100)/profile_complete_progress_total
	end

	# Get full name
	def full_name
		if first_name.present? and last_name.present?
			return first_name << " " << last_name
		else
			return user.email.split("@")[0]
		end
	end

	def get_first_name
		if first_name.present?
			return first_name
		else
			return user.email.split("@")[0]
		end
	end

	def get_profile_picture_url(size)
		begin
			return self.albums.where(name: Constant::ALBUM_PROFILE_NAME).first.photos.last.image.url(size)
		rescue
			return get_missing_profile_picture(size)
		end
	end

	def get_profesional_book_album_photos
		begin
			return self.albums.where(name: Constant::ALBUM_PROFESSIONAL_NAME).first.photos
		rescue
			return []
		end
	end

	def get_profesional_book_album_photos_count
		begin
			return self.albums.where(name: Constant::ALBUM_PROFESSIONAL_NAME).first.photos.count
		rescue
			return 0
		end
	end

	def generate_array_of_param_with_value
		parameters_with_values = [first_name.present?, 
								  last_name.present?, 
								  gender.present?, 
								  mobile_phone.present?, 
								  land_phone.present?, 
								  address.present?, 
								  current_province.present?, 
								  nationality.present?]

		parameters_with_values << add_profile_picture_album_to_progress
		parameters_with_values << add_profesional_book_album_to_progress

		return parameters_with_values
	end

	def add_profile_picture_album_to_progress
		begin
			profile_picture_album = albums.where(name: Constant::ALBUM_PROFILE_NAME).first
			if profile_picture_album.photos.any?
				return false
			end

			return true
		rescue
			return true
		end
	end

	def add_profesional_book_album_to_progress
		begin
			profesional_book_album = albums.where(name: Constant::ALBUM_PROFESSIONAL_NAME).first
			if profesional_book_album.photos.any?
				return false
			end

			return true
		rescue
			return true
		end
	end

	def can_upload_photo?(photo_type)
		current_amount = 0
		allow = true

		case photo_type
		when "profile"
			return [allow, nil]
		when "professional"
			current_amount = albums.where(name: Constant::ALBUM_PROFESSIONAL_NAME).first.photos.count

			allow = self.plan.can_upload_photo?(photo_type, current_amount)
			return allow ? [allow, nil] : [allow, I18n.t('views.albums.messages.professional_max')]
		end
	end

	def set_as_partner
		self.is_partner = true
		save
	end

	def unset_as_partner
		self.is_partner = false
		save
	end
end
