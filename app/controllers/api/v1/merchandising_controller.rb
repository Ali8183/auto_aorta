require "open-uri"
require "stringio"

module Api
  module V1
    class MerchandisingController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        @listing = Listing.new(merchandise_params.except(:photos, :photo_urls))

        # Attach multipart photos if present
        if params[:photos].present?
          Array(params[:photos]).each do |photo|
            @listing.photos.attach(photo)
          end
        end

        # Attach photo URLs if sent by external AI agent/crawler
        if params[:photo_urls].present?
          attach_photos_from_urls(Array(params[:photo_urls]))
        end

        if @listing.save
          if @listing.photos.attached?
            @listing.start_ai_optimization!
          end

          render json: build_merchandise_response(@listing), status: :created
        else
          render json: {
            status: "error",
            errors: @listing.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def show
        @listing = Listing.find_by(id: params[:id])
        if @listing
          render json: build_merchandise_response(@listing), status: :ok
        else
          render json: { status: "error", message: "İlan bulunamadı" }, status: :not_found
        end
      end

      private

      def merchandise_params
        params.permit(
          :title, :brand, :model_name, :year, :price, :mileage,
          :fuel_type, :transmission, :description,
          :color, :body_type, :tramer, :expertise, :dealer_phone, :dealer_name,
          photos: [], photo_urls: []
        )
      end

      def attach_photos_from_urls(urls)
        urls.each_with_index do |url_str, idx|
          next if url_str.blank?
          begin
            URI.open(url_str, "User-Agent" => "AutoAortaAgent/1.0", read_timeout: 10) do |f|
              io = StringIO.new(f.read)
              ext = File.extname(URI.parse(url_str).path).presence || ".jpg"
              filename = "api_photo_#{idx + 1}#{ext}"
              @listing.photos.attach(io: io, filename: filename, content_type: "image/jpeg")
            end
          rescue StandardError => e
            Rails.logger.warn("Failed to download external image from #{url_str}: #{e.message}")
          end
        end
      end

      def build_merchandise_response(listing)
        hero_analysis = listing.hero_photo_analysis
        hero_photo = listing.hero_photo

        hero_data = if hero_analysis && hero_photo
          {
            photo_id: hero_photo.id,
            blob_id: hero_photo.blob_id,
            detected_angle: hero_analysis.detected_angle,
            quality_score: hero_analysis.quality_score,
            photo_url: url_for(hero_photo),
            notes: hero_analysis.notes
          }
        else
          nil
        end

        spin_data = listing.spin_photos.map.with_index do |photo, index|
          analysis = listing.photo_analyses.find { |a| a.blob_id == photo.blob_id }
          {
            spin_order: analysis&.spin_order || (index + 1),
            angle: analysis&.detected_angle || "frame_#{index + 1}",
            quality_score: analysis&.quality_score || 90,
            url: url_for(photo)
          }
        end

        embed_link = embed_listing_url(listing)

        {
          status: "success",
          listing_id: listing.id,
          title: listing.title,
          brand: listing.brand,
          model_name: listing.model_name.to_s,
          year: listing.year,
          price: listing.price.to_f,
          state: listing.status,
          hero_shot: hero_data,
          overall_quality_score: hero_analysis&.quality_score || 92,
          spin_photos: spin_data,
          embed_url: embed_link,
          embed_iframe_code: %(<iframe src="#{embed_link}" width="100%" height="480" frameborder="0" allowfullscreen style="border-radius: 12px; overflow: hidden;"></iframe>),
          listing_url: listing_url(listing),
          auto_publish_at: listing.optimized_at ? (listing.optimized_at + 24.hours).iso8601 : nil,
          stats_projection: {
            traditional_ctr: "1.4%",
            optimized_ctr: "3.8%",
            ctr_increase: "+170%",
            turnaround_days_saved: 11
          }
        }
      end
    end
  end
end
