class PexelsService
  def fetch_videos(page = 1, per_page = 10)
    logger.info "Fetching videos from Pexels: page=#{page}, per_page=#{per_page}"

    Rails.cache.fetch("pexels_videos_page_#{page}_#{per_page}", expires_in: 30.minutes) do
      response = PexelsClient.videos.popular(page: page, per_page: per_page)

      logger.info "Successfully fetched #{response.total_results} videos from Pexels API: page=#{page}, per_page=#{per_page}"

      format_response(response, page, per_page)
    end
  rescue SocketError
    handle_error("Connection failed.", page, per_page)
  rescue Net::OpenTimeout, Net::ReadTimeout
    handle_error("Timeout.", page, per_page)
  rescue StandardError => e
    handle_error("Unknown error: #{e.message}", page, per_page)
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

  def handle_error(error, page, per_page)
    logger.error "Error while fetching videos from Pexels: #{error} (page=#{page}, per_page=#{per_page})"

    {
      items: [],
      page: page,
      per_page: per_page,
      total_pages: 0,
      error: error
    }
  end

  def logger
    @logger ||= Rails.logger
  end
end
