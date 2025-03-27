class Api::V1::VideosController < ApplicationController
  before_action :authenticate_token

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 10

    service = PexelsService.new
    videos = service.fetch_videos(page, per_page)

    render json: videos
  end

  private

  def authenticate_token
    token = request.headers["Authorization"]
    unless token && ActiveSupport::SecurityUtils.secure_compare(token, ENV["BACKEND_API_KEY"])
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
