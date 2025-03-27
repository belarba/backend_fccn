class PexelsService
  def fetch_videos(page = 1, per_page = 10)
    response = PexelsClient.videos.popular(page: page, per_page: per_page)
    format_response(response, page, per_page)
  end

  private

  def format_response(response, page, per_page)
    {
      items: response.map do |video|
        {
          id: video.id,
          width: video.width,
          height: video.height,
          duration: video.duration,
          user_name: video.user.name,
          video_files: video.files.map { |file| { link: file.link, quality: file.quality } },
          video_pictures: video.pictures.map(&:picture)
        }
      end,
      page: page,
      per_page: per_page,
      total_pages: (response.total_results.to_f / per_page).ceil
    }
  end
end
