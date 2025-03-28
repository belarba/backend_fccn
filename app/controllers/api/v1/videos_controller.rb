class Api::V1::VideosController < ApplicationController
  before_action :authenticate_token

  def index
    logger.info "Received request for Videos: page=#{params[:page]} per_page=#{params[:per_page]} query=#{params[:query]} locale=#{params[:locale]} size=#{params[:size]}"

    page, per_page = extract_pagination_params
    query_params = extract_query_params
    videos = fetch_videos(page, per_page, query_params)

    logger.info "Successfully fetched videos for page #{page} with per_page #{per_page}"
    render json: videos, status: :ok
  rescue StandardError => e
    logger.error "Error fetching videos: #{e.message}"
    render json: { error: "Error fetching videos: #{e.message}" }, status: :internal_server_error
  end

  private

  def authenticate_token
    token = request.headers["Authorization"]
    unless token && ActiveSupport::SecurityUtils.secure_compare(token, ENV["BACKEND_API_KEY"])
      logger.warn "Unauthorized access attempt detected."
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def extract_pagination_params
    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 10
    [ page, per_page ]
  end

  def extract_query_params
    {
      locale: params[:locale].presence,
      size: params[:size].presence
    }.compact
  end

  def fetch_videos(page, per_page, query_params = {})
    if params[:query].present?
      PexelsService.new.search_videos(params[:query], page, per_page, query_params)
    else
      PexelsService.new.fetch_videos(page, per_page, query_params)
    end
  end
end
