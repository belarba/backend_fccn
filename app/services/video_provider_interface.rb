module VideoProviderInterface
  def fetch_videos(page = 1, per_page = 10, options = {})
    raise NotImplementedError, "#{self.class} deve implementar o método #fetch_videos"
  end

  def search_videos(query, page = 1, per_page = 10, options = {})
    raise NotImplementedError, "#{self.class} deve implementar o método #search_videos"
  end

  def fetch_video_by_id(id)
    raise NotImplementedError, "#{self.class} deve implementar o método #fetch_video_by_id"
  end
end
