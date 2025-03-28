class PexelsService
  def fetch_videos(page = 1, per_page = 10, options = {})
    logger.info "Fetching popular videos from Pexels: page=#{page}, per_page=#{per_page}, options=#{options}"

    cache_key = build_cache_key("popular", page, per_page, options)

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      response = PexelsClient.videos.popular

      paginated_items = paginate_items(response.videos, page, per_page)

      {
        items: format_items(paginated_items),
        page: page,
        per_page: per_page,
        total_pages: (response.videos.length.to_f / per_page).ceil
      }
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
      search_params = {
        page: page,
        per_page: per_page
      }

      search_params[:size] = translate_size(options[:size]) if options[:size].present?

      response = PexelsClient.videos.search(query, **search_params)

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

  def filter_items(items, options)
    filtered = items

    if options[:size].present?
      size_value = translate_size(options[:size])
      if size_value
        filtered = filtered.select do |video|
          case size_value
          when :large  # HD (720p)
            video.height >= 720 && video.height < 1080
          when :medium # FullHD (1080p)
            video.height >= 1080 && video.height < 2160
          when :small  # 4K
            video.height >= 2160
          else
            true
          end
        end
      end
    end

    filtered
  end

  def paginate_items(items, page, per_page)
    start_index = (page - 1) * per_page
    end_index = start_index + per_page - 1

    end_index = [ end_index, items.length - 1 ].min if items.length > 0

    return [] if start_index >= items.length

    items[start_index..end_index]
  end

  def format_items(items)
    items.map do |video|
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
    end
  end

  def build_cache_key(prefix, page, per_page, options)
    options_key = options.map { |k, v| "#{k}_#{v}" }.join("_")
    "pexels_#{prefix}_page_#{page}_#{per_page}_#{options_key}"
  end

  def translate_size(size)
    case size.to_s.downcase
    when "hd"
      :large
    when "fullhd"
      :medium
    when "4k"
      :small
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
