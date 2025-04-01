class Api::V1::VideosController < ApplicationController
  before_action :authenticate_token
  before_action :set_video_provider

  def index
    logger.info "Received request for Videos: page=#{params[:page]} per_page=#{params[:per_page]} query=#{params[:query]} size=#{params[:size]}"

    @page, @per_page = extract_pagination_params
    query_params = extract_query_params

    result = if params[:query].present? && !params[:query].strip.empty?
      # Se tiver uma consulta não vazia, use search
      @video_provider.search_videos(params[:query], @page, @per_page, query_params)
    else
      # Sem consulta específica, use o método para vídeos populares
      @video_provider.fetch_videos(@page, @per_page, query_params)
    end

    if result[:error].present?
      render json: { error: result[:error] }, status: :internal_server_error
      return
    end

    @videos = result[:items]
    @total_pages = result[:total_pages]

    logger.info "Successfully fetched videos for page #{@page} with per_page #{@per_page}"

    respond_to do |format|
      format.json # will render index.json.jbuilder
    end
  rescue StandardError => e
    logger.error "Error fetching videos: #{e.message}"
    render json: { error: "Error fetching videos: #{e.message}" }, status: :internal_server_error
  end

  def show
    logger.info "Received request for Video with ID: #{params[:id]}"

    result = @video_provider.fetch_video_by_id(params[:id])

    if result[:error].present?
      logger.error "Error fetching video: #{result[:error]}"
      render json: { error: result[:error] }, status: :not_found
      return
    end

    @video = result
    @video_files = result[:video_files]

    logger.info "Successfully fetched video with ID: #{params[:id]}"

    respond_to do |format|
      format.json # will render show.json.jbuilder
    end
  rescue StandardError => e
    logger.error "Error fetching video: #{e.message}"
    render json: { error: "Error fetching video: #{e.message}" }, status: :internal_server_error
  end

  private

  # Método auxiliar para determinar a resolução na view show
  helper_method :determine_resolution
  def determine_resolution(height)
    if height >= 2160
      "4K"
    elsif height >= 1080
      "FullHD"
    elsif height >= 720
      "HD"
    else
      "SD"
    end
  end

  # Métodos existentes
  def set_video_provider
    @video_provider = VideoProviderFactory.create(:pexels)
  end

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
