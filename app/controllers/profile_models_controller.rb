class ProfileModelsController < ApplicationController
  before_action :authenticate_user!, only: [:show, :new, :create, :edit, :update]
  before_action :set_profile, only: [:show, :show_resume, :show_for_review, :show_professional_photos, :show_polaroid_photos, :show_selected_photo, :vote, :publish, :no_publish, :edit, :update, :destroy]
  before_action :generate_cols_batch, only: [:show, :show_professional_photos]
  before_action :generate_cols_batch_polaroid, only: [:show_polaroid_photos]
  before_action :check_if_can, only: [:show_for_review, :publish, :no_publish, :edit, :update, :destroy]

  def index
    @models = ProfileModel.ready
  end

  def index_search
    @search = Search.new
    @models = ProfileModel.ready
  end

  def perform_search
    @search = Search.new(search_params)
    @models = @search.perform("models")

    respond_to do |format|
      format.js
    end
  end

  def show
    generate_needed_info
    respond_to do |format|
      format.html
    end
  end

  def show_professional_photos
    respond_to do |format|
      format.js
    end
  end

  def show_polaroid_photos
    respond_to do |format|
      format.js
    end
  end

  def show_selected_photo
    @photo = @profile.photos.find(params[:photo_id])
    respond_to do |format|
      format.js
    end
  end

  def vote
    set_votant

    respond_to do |format|
      @voted = @profile.try_vote!(@votant)
      @new_count = @profile.get_votes_count
      format.js
    end
  end

  def show_resume
    respond_to do |format|
      format.js
    end
  end

  def show_for_review
    respond_to do |format|
      format.html
    end
  end

  def publish
    @profile.publish

    respond_to do |format|
      if @profile.save
        Message.create(template: "inbox_message_profile_published", ownerable: @profile, asociateable: @profile)
        format.js
      else
        format.js
      end
    end
  end

  def no_publish
    Message.create(template: "inbox_message_profile_unpublished", ownerable: @profile, asociateable: @profile)
    
    respond_to do |format|
      format.js
    end
  end

  def new
    if current_user.profileable.nil?
      @profile = ProfileModel.create
      build_profile_meta

      authorize! :new, @profile

      current_user.profileable = @profile
      current_user.save

      redirect_to edit_profile_model_path(@profile)
    else
      redirect_to edit_profile_model_path(current_user.profileable)
    end
  end

  def create
    redirect_to new_profile_model_path
  end

  def edit
    @album_profile_picture = @profile.albums.where(name: "Profile Photo").first

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    respond_to do |format|
      if @profile.update(profile_params)
        @update_progress = @profile.profile_complete_progress_percentage
        format.html { redirect_to '/', success: 'Your profile has been updated ' + @profile.full_name + '.' }
        format.js
      else
        format.html { render action: 'edit' }
        format.js
      end
    end
  end

  def destroy
  end

  private

    def profile_params
      params.require(:profile_model).permit(:first_name, :last_name, :mobile_phone,
                                            :birth_date, :land_phone, :address, :chest, :waist, 
                                            :hips, :ayes_color_id, :current_province_id, 
                                            :gender, :size_shoes, :size_cloth, :nationality_id,
                                            :height, :reviewed, :ethnicity_id, expertise_ids:[], 
                                            language_ids:[], modality_ids:[], category_ids:[])
    end

    def search_params
      params.require(:search).permit(:province_id, :nationality_id, :age_from, :age_to, 
                                     :gender, :height_from, :heigth_to, :new_face, 
                                     :professional_model, modality_ids:[], category_ids:[])
    end

    def set_profile
      @profile = ProfileModel.find(params[:id])
    end

    def set_votant
      class_name = params[:votant_type]

      case class_name
      when "ProfileContractor"
        @votant = ProfileContractor.find(params[:votant_id])
      when "ProfileModel"
        @votant = ProfileModel.find(params[:votant_id])
      when "ProfilePhotographer"
        @votant = ProfilePhotographer.find(params[:votant_id])
      end
    end

    def check_if_can
      authorize! action_name.to_s.to_sym, @profile
    end

    def build_profile_meta
      @profile.albums.create(name: "Profile Photo")
      @profile.albums.create(name: "Profesional Book")
      @profile.albums.create(name: "Polaroid")
    end

    def generate_cols_batch
      @cols = []
      count = @profile.get_profesional_book_album_photos_count
      rest = count % 3
      value = (count / 3).to_i

      case rest
      when 0
        @cols = [value, value, value]
      when 1
        @cols = [value + 1, value, value]
      when 2
        @cols = [value + 1, value + 1, value]
      end
    end

    def generate_cols_batch_polaroid
      @cols = []
      count = @profile.albums.where(name: "Polaroid").first.photos.count
      rest = count % 3
      value = (count / 3).to_i

      case rest
      when 0
        @cols = [value, value, value]
      when 1
        @cols = [value + 1, value, value]
      when 2
        @cols = [value + 1, value + 1, value]
      end
    end

    def generate_needed_info
      @review = Review.new
      @language_cols_batch = @profile.languages.any? ? (@profile.languages.count.to_f / 2).ceil : 0
      @modality_cols_batch = @profile.modalities.any? ? (@profile.modalities.count.to_f / 2).ceil : 0
      @category_cols_batch = @profile.categories.any? ? (@profile.categories.count.to_f / 2).ceil : 0
    end
end
