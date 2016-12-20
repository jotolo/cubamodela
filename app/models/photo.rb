class Photo < ApplicationRecord
  # Associations
  belongs_to :attachable, polymorphic: true

  # Image
  has_attached_file :image, styles: { 
	  					original:{
	  						:geometry => '800x300^'
	  					},
	  					tiny:{
	  						:geometry => '32x32'
	  					}, 
	  					small:{
	  						:geometry => '64x64'
	  					}, 
	  					medium:{
	  						:processors => [:watermark],
	  						:geometry => '128x128',
							:watermark_path => "#{Rails.root}/app/assets/images/watermark_medium.png",
							:position => 'SouthEast',
							:watermark_dissolve => 90,
							:auto_orient => false 
	  					}, 
	  					large:{
	  						:processors => [:watermark],
	  						:geometry => '256x256',
							:watermark_path => "#{Rails.root}/app/assets/images/watermark_large.png",
							:position => 'SouthEast',
							:watermark_dissolve => 90,
							:auto_orient => false 
	  					},
	  					big:{
	  						:processors => [:watermark],
	  						:geometry => '800x300^',
							:watermark_path => "#{Rails.root}/app/assets/images/watermark_big.png",
							:position => 'NorthEast',
							:watermark_dissolve => 90,
							:auto_orient => false 
	  					} 
  					}, 
  					:default_url => "/images/paperclip_missing_photo.JPG"

  # Validations
  validates_attachment :image, :presence => true,
							   :content_type => { :content_type => /^image\/(jpeg|jpg|png|gif)$/ },
							   :size => { :in => 0..30.megabytes }
end
