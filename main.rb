require 'ruby-progressbar'
require 'pry'
require 'httpclient'
require 'json'
require 'pp'
require 'active_support/all'
require 'eventmachine'
require 'zlib'
require 'treat'

require_relative './get_lyrics'
require_relative './chain'

include Treat::Core::DSL

tm = TransitionMatrix.new

artist = Artist.new(ARGV.join(' '))
string = artist.lyrics.gsub(/[^a-z' \n]/i, '').downcase
words = paragraph(string).segment.map(&:tokenize).flatten

words.each_cons(3) do |word_triplet|
  tm.add(*word_triplet)
end

first_word, second_word = tm.keys.sample.split
10.times do
  out = 8.times.inject([first_word, second_word]) do |new_words, _|
    new_words.push tm.get_next(new_words[-2] + ' ' + new_words[-1])
  end
  next_word = tm.get_next(out[-2] + ' ' + out[-1])
  first_word, second_word = next_word, tm.get_next(out[-1] + ' ' + next_word)

  puts out.join(' ')
end
