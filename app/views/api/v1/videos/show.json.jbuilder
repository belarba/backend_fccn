json.id @video[:id]
json.width @video[:width]
json.height @video[:height]
json.duration @video[:duration]

json.user do
  json.name @video[:user][:name]
  json.url @video[:user][:url]
end

json.video_files do
  json.sd @video_files[:sd] do |file|
    json.link file[:link]
    json.quality file[:quality]
    json.width file[:width]
    json.height file[:height]
    json.file_type file[:file_type]
  end

  json.hd @video_files[:hd] do |file|
    json.link file[:link]
    json.quality file[:quality]
    json.width file[:width]
    json.height file[:height]
    json.file_type file[:file_type]
  end

  json.full_hd @video_files[:full_hd] do |file|
    json.link file[:link]
    json.quality file[:quality]
    json.width file[:width]
    json.height file[:height]
    json.file_type file[:file_type]
  end

  json.uhd @video_files[:uhd] do |file|
    json.link file[:link]
    json.quality file[:quality]
    json.width file[:width]
    json.height file[:height]
    json.file_type file[:file_type]
  end
end

json.video_pictures @video[:video_pictures]
json.resolution @video[:resolution]
json.url @video[:url]
