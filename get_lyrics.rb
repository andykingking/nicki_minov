$http = HTTPClient.new

Track = Struct.new(:name, :artist) do
  def get
    proc {
      endpoint = "http://lyrics.wikia.com/api.php?artist=#{CGI::escape artist.to_s}&song=#{CGI::escape name}&fmt=realjson"
      $http.get(endpoint).body
    }
  end
end

Artist = Struct.new(:name) do
  def get_tracks
    response = JSON.parse $http.get(endpoint).body
    song_names = response['albums'].flat_map { |album| album['songs'] }
    song_names.map { |song_name| Track.new(song_name, self) }
  end

  def endpoint
    "http://lyrics.wikia.com/api.php?func=getArtist&artist=#{CGI::escape name}&fmt=realjson"
  end

  def tracks
    @tracks ||= get_tracks
  end

  def get_lyrics_from_cache
    if File.exists?(cache_filename)
      @lyrics = Zlib::Inflate.inflate(File.read(cache_filename))
      puts '> Found cached tracks'
      return true
    end
  end

  def cache_filename
    @cache_filename ||= File.join(File.dirname(__FILE__), 'cache', "#{name.gsub(/ /, '_').underscore}.cache")
  end

  alias_method :to_s, :name

  def lyrics
    unless get_lyrics_from_cache
      return unless tracks.length > 0

      text = ""
      tracks_remaining = tracks.length
      bar = ProgressBar.create(:title => 'Fetching tracks', :total => tracks_remaining, :format => '> %t %c/%C %B')
      EM.run do
        tracks.each_with_index.map do |track, index|
          EM.defer(track.get, proc { |response|
            text << ' ' + JSON.parse(response)['lyrics']
            tracks_remaining -= 1
            bar.increment
            EM.stop_event_loop if tracks_remaining <= 0
          })
        end
      end

      File.open(cache_filename, 'wb+') { |file| file.write(Zlib::Deflate.deflate(text, Zlib::BEST_COMPRESSION)) }
      @lyrics = text
    end

    @lyrics
  end
end

