class PexelsVideoProvider
  include VideoProviderInterface

  MAX_RESULT_INITIAL_PAGE = 16.freeze

  def initialize(formatter: VideoFormatterService.new, filter: VideoFilterService.new)
    @formatter = formatter
    @filter = filter
  end

  def fetch_videos(page = 1, per_page = 10, options = {})
    logger.info "Fetching popular videos from Pexels: page=#{page}, per_page=#{per_page}, options=#{options}"

    cache_key = build_cache_key("popular", page, per_page, options)

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      response = PexelsClient.videos.popular(per_page: MAX_RESULT_INITIAL_PAGE)

      filtered_videos = @filter.filter_by_size(response.videos, options[:size])
      paginated_items = @filter.paginate_items(filtered_videos, page, per_page)

      @formatter.format_videos_response(paginated_items, page, per_page)
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

      search_params[:size] = options[:size] if options[:size].present?

      response = PexelsClient.videos.search(query, **search_params)

      if response.total_results.zero?
        logger.warn "No videos found for query=#{query}, page=#{page}, per_page=#{per_page}, options=#{options}. Skipping cache."
        return @formatter.format_search_response(response, page, per_page)
      end

      logger.info "Successfully searched #{response.total_results} videos from Pexels API: query=#{query}, page=#{page}, per_page=#{per_page}"
      @formatter.format_search_response(response, page, per_page)
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

  def fetch_video_by_id(id)
    logger.info "Fetching video with ID: #{id} from Pexels"

    cache_key = "pexels_video_#{id}"

    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      begin
        video = PexelsClient.videos.find(id)

        if video.nil?
          return { error: "Video not found" }
        end

        @formatter.format_video_detail(video)
      rescue Pexels::APIError => e
        logger.error "Pexels API Error: #{e.message}"
        { error: "Video not found" }
      end
    end
  rescue SocketError
    { error: "Connection failed" }
  rescue Net::OpenTimeout, Net::ReadTimeout
    { error: "Timeout" }
  rescue JSON::ParserError
    { error: "Invalid JSON response from Pexels" }
  rescue StandardError => e
    logger.error "Error while fetching video: #{e.message}"
    { error: "Unknown error: #{e.message}" }
  end

  private

  def build_cache_key(prefix, page, per_page, options)
    options_key = options.map { |k, v| "#{k}_#{v}" }.join("_")
    "pexels_#{prefix}_page_#{page}_#{per_page}_#{options_key}"
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
