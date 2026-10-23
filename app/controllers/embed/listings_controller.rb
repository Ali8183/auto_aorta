module Embed
  class ListingsController < ApplicationController
    layout "embed"
    before_action :set_listing
    before_action :allow_iframe

    def show
      @spin_photos = @listing.spin_photos
      @hero_analysis = @listing.hero_photo_analysis
      @photo_analyses = @listing.photo_analyses.order(:spin_order)
    end

    private

    def set_listing
      @listing = Listing.find(params[:id])
    end

    def allow_iframe
      response.headers.delete("X-Frame-Options")
      response.headers["Content-Security-Policy"] = "frame-ancestors *"
    end
  end
end
