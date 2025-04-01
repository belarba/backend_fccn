json.items @videos do |video|
  json.partial! "api/v1/videos/video", video: video
end

json.page @page
json.per_page @per_page
json.total_pages @total_pages
