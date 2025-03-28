class PexelsService
  def fetch_videos(page = 1, per_page = 10, options = {})
    logger.info "Fetching popular videos from Pexels: page=#{page}, per_page=#{per_page}, options=#{options}"

    cache_key = build_cache_key("popular", page, per_page, options)

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      client_params = { page: page, per_page: per_page }
      client_params[:locale] = options[:locale] if options[:locale].present?
      client_params[:size] = translate_size(options[:size]) if options[:size].present?

      response = PexelsClient.videos.popular(client_params)

      if response.total_results.zero?
        logger.warn "No videos found for page=#{page}, per_page=#{per_page}, options=#{options}. Skipping cache."
        return format_response(response, page, per_page)
      end

      logger.info "Successfully fetched #{response.total_results} videos from Pexels API: page=#{page}, per_page=#{per_page}"
      format_response(response, page, per_page)
    end
  rescue SocketError
    handle_error("Connection failed.", page, per_page)
  rescue Net::OpenTimeout, Net::ReadTimeout
    handle_error("Timeout.", page, per_page)
  rescue JSON::ParserError
    handle_error("Invalid JSON response from Pexels.", page, per_page)
  rescue StandardError => e
    handle_error("Unknown error: #{e.message}", page, per_page)
  end

  def search_videos(query, page = 1, per_page = 10, options = {})
    logger.info "Searching videos from Pexels: query=#{query}, page=#{page}, per_page=#{per_page}, options=#{options}"

    cache_key = build_cache_key("search_#{query}", page, per_page, options)

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      client_params = {
        query: query,
        page: page,
        per_page: per_page
      }
      client_params[:locale] = options[:locale] if options[:locale].present?
      client_params[:size] = translate_size(options[:size]) if options[:size].present?

      response = PexelsClient.videos.search(client_params)

      if response.total_results.zero?
        logger.warn "No videos found for query=#{query}, page=#{page}, per_page=#{per_page}, options=#{options}. Skipping cache."
        return format_response(response, page, per_page)
      end

      logger.info "Successfully searched #{response.total_results} videos from Pexels API: query=#{query}, page=#{page}, per_page=#{per_page}"
      format_response(response, page, per_page)
    end
  rescue SocketError
    handle_error("Connection failed.", page, per_page)
  rescue Net::OpenTimeout, Net::ReadTimeout
    handle_error("Timeout.", page, per_page)
  rescue JSON::ParserError
    handle_error("Invalid JSON response from Pexels.", page, per_page)
  rescue StandardError => e
    handle_error("Unknown error: #{e.message}", page, per_page)
  end

  private

  def build_cache_key(prefix, page, per_page, options)
    options_key = options.map { |k, v| "#{k}_#{v}" }.join("_")
    "pexels_#{prefix}_page_#{page}_#{per_page}_#{options_key}"
  end

  def translate_size(size)
    case size.to_s.downcase
    when "hd"
      "large"
    when "fullhd"
      "medium"
    when "4k"
      "small"
    else
      nil
    end
  end

  def format_response(response, page, per_page)
    {
      items: response.map do |video|
        {
          id: video.id,
          width: video.width,
          height: video.height,
          duration: video.duration,
          user_name: video.user.name,
          video_files: video.files.map { |file|
            {
              link: file.link,
              quality: file.quality,
              width: file.width,
              height: file.height
            }
          },
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
