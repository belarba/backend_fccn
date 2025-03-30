class VideoFilterService
  def filter_by_size(videos, size_option)
    return videos unless size_option.present?

    size_value = translate_size(size_option)
    return videos unless size_value

    videos.select do |video|
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

  def paginate_items(items, page, per_page)
    start_index = (page - 1) * per_page
    end_index = start_index + per_page - 1

    end_index = [ end_index, items.length - 1 ].min if items.length > 0

    return [] if start_index >= items.length

    items[start_index..end_index]
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
end
