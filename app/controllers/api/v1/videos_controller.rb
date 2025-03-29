class Api::V1::VideosController < ApplicationController
  before_action :authenticate_token

  def index
    logger.info "Received request for Videos: page=#{params[:page]} per_page=#{params[:per_page]} query=#{params[:query]} size=#{params[:size]}"

    page, per_page = extract_pagination_params
    query_params = extract_query_params

    videos = if params[:query].present? && !params[:query].strip.empty?
      # Se tiver uma consulta não vazia, use search
      PexelsService.new.search_videos(params[:query], page, per_page, query_params)
    else
      # Sem consulta específica, use o método para vídeos populares
      PexelsService.new.fetch_videos(page, per_page, query_params)
    end

    logger.info "Successfully fetched videos for page #{page} with per_page #{per_page}"
    render json: videos, status: :ok
  rescue StandardError => e
    logger.error "Error fetching videos: #{e.message}"
    render json: { error: "Error fetching videos: #{e.message}" }, status: :internal_server_error
  end

  def show
    logger.info "Received request for Video with ID: #{params[:id]}"

    video = PexelsService.new.fetch_video_by_id(params[:id])

    if video[:error].present?
      logger.error "Error fetching video: #{video[:error]}"
      render json: { error: video[:error] }, status: :not_found
    else
      logger.info "Successfully fetched video with ID: #{params[:id]}"
      render json: video, status: :ok
    end
  rescue StandardError => e
    logger.error "Error fetching video: #{e.message}"
    render json: { error: "Error fetching video: #{e.message}" }, status: :internal_server_error
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
      size: params[:size].presence
    }.compact
  end
end
