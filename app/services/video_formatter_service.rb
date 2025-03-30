class VideoFormatterService
  def format_videos_response(videos, page, per_page)
    {
      items: format_items(videos),
      page: page,
      per_page: per_page,
      total_pages: calculate_total_pages(videos.length, per_page)
    }
  end

  def format_search_response(response, page, per_page)
    {
      items: response.map { |video| format_video_item(video) },
      page: page,
      per_page: per_page,
      total_pages: (response.total_results.to_f / per_page).ceil
    }
  end

  def format_video_detail(video)
    {
      id: video.id,
      width: video.width,
      height: video.height,
      duration: video.duration,
      user: {
        name: video.user.name,
        url: video.user.url
      },
      video_files: categorize_video_files(video.files),
      video_pictures: video.pictures.map(&:picture),
      resolution: determine_resolution(video.height),
      url: video.url
    }
  end

  private

  def format_items(items)
    items.map { |video| format_video_item(video) }
  end

  def format_video_item(video)
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

  def categorize_video_files(files)
    categorized = {
      sd: [],
      hd: [],
      full_hd: [],
      uhd: []
    }

    files.each do |file|
      quality = determine_quality(file.height)
      categorized[quality] << {
        link: file.link,
        quality: file.quality,
        width: file.width,
        height: file.height,
        file_type: file.file_type
      }
    end

    categorized.each do |key, value|
      categorized[key] = value.sort_by { |f| f[:height] }.reverse
    end

    categorized
  end

  def determine_quality(height)
    if height <= 480
      :sd
    elsif height <= 720
      :hd
    elsif height <= 1080
      :full_hd
    else
      :uhd
    end
  end

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

  def calculate_total_pages(total_items, per_page)
    (total_items.to_f / per_page).ceil
  end
end
