class Casting < ApplicationRecord
  # Status
  enum status: [:active, :closed, :canceled]

  after_initialize :set_default_status, if: :new_record?

  def set_default_status
  	self.status ||= :active
  end

  # Access Type
  enum access_type: [:free, :personal]

  after_initialize :set_default_access_type, if: :new_record?

  def set_default_access_type
    self.access_type ||= :free
  end

  # Locale
  before_save :set_title_locale, if: :new_record?
  before_save :set_description_locale, if: :new_record?
  before_save :set_location_locale, if: :new_record?

  def set_title_locale
    if I18n.locale == "en".to_sym
      self.title_es ||= "traduccion pendiente"
    else
      self.title_en ||= "pending translation"
    end
  end

  def set_description_locale
    if I18n.locale == "en".to_sym
      self.description_es ||= "traduccion pendiente"
    else
      self.description_en ||= "pending translation"
    end
  end

  def set_location_locale
    if I18n.locale == "en".to_sym
      self.location_es ||= "traduccion pendiente"
    else
      self.location_es ||= "pending translation"
    end
  end

  # Validations
  validates :title_en, presence: true, length: { in: 3..50 }, if: :locale_en?
  validates :title_es, presence: true, length: { in: 3..50 }, if: :locale_es?
  validates :description_en, presence: true, length: { in: 20..500 }, if: :locale_en?
  validates :description_es, presence: true, length: { in: 20..500 }, if: :locale_es?
  validates :location_en, length: { in: 5..500 }, allow_blank: true, if: :locale_en?
  validates :location_es, length: { in: 5..500 }, allow_blank: true, if: :locale_es?
  validates :expiration_date, presence: true
  validates :casting_date, presence: true
  validates :shooting_date, presence: true
  validate :expiration_date_cannot_be_in_the_past, :casting_date_cannot_be_in_the_past, :shooting_date_cannot_be_in_the_past
  validates :access_type, inclusion: { in: %w(free personal) }

  #Scopes
  scope :actives, -> { where(status: "active").order("created_at DESC") }
  scope :valid_castings, -> { where(status: ["active", "closed"]).where("casting_date > :today", today: DateTime.now).order("created_at DESC") }

  # Associations	
  belongs_to :ownerable, polymorphic: true
  has_many :intents, dependent: :destroy
  has_many :invited_intents, -> { where(status: "invited") }, class_name: "Intent"
  has_many :confirmed_intents, -> { where(status: "confirmed") }, class_name: "Intent"
  has_many :applied_intents, -> { where(status: "applied") }, class_name: "Intent"
  has_many :profile_models, through: :intents
  has_many :photos, as: :attachable, dependent: :destroy
  has_and_belongs_to_many :modalities, dependent: :destroy
  has_and_belongs_to_many :categories, dependent: :destroy

  # Custom Validators
  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < DateTime.now
      errors.add(:expiration_date, :wrong_expiration_date)
    end
  end

  def casting_date_cannot_be_in_the_past
    if casting_date.present? && (casting_date < DateTime.now || casting_date <= expiration_date)
      errors.add(:casting_date, :wrong_casting_date)
    end
  end

  def shooting_date_cannot_be_in_the_past
    if shooting_date.present? && (shooting_date < DateTime.now || shooting_date <= casting_date)
      errors.add(:shooting_date, :wrong_shooting_date)
    end
  end

  def locale_en?
    return I18n.locale == "en".to_sym
  end

  def locale_es?
    return I18n.locale == "es".to_sym
  end

  # Get attrs
  def title
    case I18n.locale
    when "en".to_sym
      return self.title_en
    when "es".to_sym
      return self.title_es
    end
  end

  def description
    case I18n.locale
    when "en".to_sym
      return self.description_en
    when "es".to_sym
      return self.description_es
    end
  end

  def location
    case I18n.locale
    when "en".to_sym
      return self.location_en
    when "es".to_sym
      return self.location_es
    end
  end

  # Action methods on casting

  def get_first_base_error
    if errors[:base].any?
      return errors[:base][0]
    else
      return ""
    end
  end

  def expired?
    return expiration_date < DateTime.now
  end

  def allow_edit?
    case status
    when "active"
      return nil
    when "closed"
      if DateTime.now < casting_date
        return nil
      else
        return I18n.t('views.castings.messages.edit.past')
      end
    when "canceled"
      return I18n.t('views.castings.messages.edit.canceled')
    end
  end

  def try_close!
    case status
    when "active"
      expiration_date = DateTime.now
      closed!
    when "closed"
      errors[:base] << I18n.t('views.castings.messages.edit.closed')
    when "canceled"
      errors[:base] << I18n.t('views.castings.messages.edit.canceled')
    end
  end

  def try_cancel!
    case status
    when "active"
      canceled!
    when "closed"
      if DateTime.now < casting_date
        canceled!
      else
        errors[:base] << I18n.t('views.castings.messages.edit.past')
      end
    when "canceled"
      errors[:base] << I18n.t('views.castings.messages.edit.canceled')
    end
  end

  def try_activate!
    case status
    when "active"
      errors[:base] << I18n.t('views.castings.messages.edit.active')
    when "closed"
      if DateTime.now < casting_date
        expiration_date = DateTime.now + 1
        casting_date = casting_date + 1
        shooting_date = shooting_date + 1
        active!
      else
        errors[:base] << I18n.t('views.castings.messages.edit.past')
      end
    when "canceled"
      errors[:base] << I18n.t('views.castings.messages.edit.canceled')
    end
  end

  def get_first_references_photo
    return photos.first
  end

  def get_rest_references_photo
    return photos.offset(1).limit(4)
  end

  def try_invite!(profile)
    intent = Intent.new

    case status
    when "active"
      intent = Intent.new(casting: self, profile_model: profile, status: "invited")
    when "closed"
      if DateTime.now < casting_date
        intent = Intent.new(casting: self, profile_model: profile, status: "invited")
      else
        intent.errors[:base] << I18n.t('views.castings.messages.edit.past')
      end
    when "canceled"
      intent.errors[:base] << I18n.t('views.castings.messages.edit.canceled')
    end

    return intent
  end

  def try_confirm!(profile)
    intent = Intent.where(profile_model_id: profile.id).first
    intent ||= Intent.new

    if intent.new_record?
      intent.errors[:base] << I18n.t('views.castings.messages.associations.confirmed_denied_no_intent')
    else
      case status
      when "active"
        intent.confirmed!
      when "closed"
        if DateTime.now < casting_date
          intent.confirmed!
        else
          intent.errors[:base] << I18n.t('views.castings.messages.edit.past')
        end
      when "canceled"
        intent.errors[:base] << I18n.t('views.castings.messages.edit.canceled')
      end
    end

    return intent
  end

  def try_apply!(profile)
    intent = Intent.new

    case status
    when "active"
      if free?
        intent = Intent.new(casting: self, profile_model: profile, status: "applied")
      else
        intent.errors[:base] << I18n.t('views.castings.messages.associations.applied_denied_personal')
      end
    when "closed"
      intent.errors[:base] << I18n.t('views.castings.messages.associations.applied_denied_closed')
    when "canceled"
      intent.errors[:base] << I18n.t('views.castings.messages.edit.canceled')
    end

    return intent
  end

  def send_update_notification(old_casting)
    if old_casting.expiration_date != expiration_date || old_casting.casting_date != casting_date || old_casting.shooting_date != shooting_date
      CastingDatesChangedJob.perform_later(self)
    end
  end
end
