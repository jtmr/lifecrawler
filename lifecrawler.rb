# -*- coding: utf-8 -*-
require 'mechanize'
require 'httpclient'

sleep_sec = 5

agent = Mechanize.new
page = agent.get('http://www.tbsradio.jp/life/themearchive.html')

page.search('h5>a').each do |themes_link|
  theme_dir = themes_link.text.gsub('/', '_')
  FileUtils.mkdir(theme_dir) unless Dir.exist?(theme_dir)
  puts 'テーマ: ' + theme_dir

  current_theme = themes_link.attr('href')
  theme = agent.get(current_theme)

  theme.search('div.entry').each do |entry|
    title = entry.search('h3').text.gsub('/', '_')
    url = ''
    entry.search('div.entry-body a').each do |link|
      if link.attr('href') =~ /mp3$/
        url = link.attr('href')
        break
      end
    end
    next if url.empty?

    # download mp3
    puts '次のパートをダウンロード: ' + title
    hc = HTTPClient.new
    hc.receive_timeout = 3000
    local_mp3 = File.join(theme_dir, title + '.mp3')
    start_time = Time.now
    
    content_length = hc.head(url).header['Content-Length'][0].to_i
    local_length = 0
    local_length = File.size(local_mp3) if File.exist?(local_mp3)
    puts " ファイルサイズ(ローカル/サーバ): #{local_length} / #{content_length}"
    if File.exist?(local_mp3) and local_length == content_length then
      puts 'ダウンロード済: ' + title
    else
      File.open(local_mp3, 'w+b') do |file|
        begin 
          hc.get_content(url) do |chunk|
            file << chunk
          end
        rescue HTTPClient::BadResponseError
          nil
        end
      end
      download_sec = Time.now - start_time
      puts 'ダウンロード完了: ' + title
      puts "経過秒数: #{download_sec}秒"
    
      puts "待機: #{sleep_sec}秒"
      sleep sleep_sec
    end
  end

  puts "待機: #{sleep_sec}秒"
  sleep sleep_sec
  puts
end

