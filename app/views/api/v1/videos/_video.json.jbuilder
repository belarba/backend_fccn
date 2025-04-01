json.id video[:id]
json.width video[:width]
json.height video[:height]
json.duration video[:duration]
json.user_name video[:user_name]

json.video_files video[:video_files] do |file|
  json.link file[:link]
  json.quality file[:quality]
  json.width file[:width]
  json.height file[:height]
  json.file_type file[:file_type] if file[:file_type].present?
end

json.video_pictures video[:video_pictures]
json.url video[:url] if video[:url].present?
