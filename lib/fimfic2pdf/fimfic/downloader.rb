# frozen_string_literal: true

require 'date'
require 'nokogiri'

require 'fimfic2pdf/downloader'

module FiMFic2PDF
  module FiMFic
    # Fetches and unpacks EPUB archives from FiMFiction
    class Downloader < FiMFic2PDF::Downloader
      def initialize(story_id)
        super
        @story_url = "https://www.fimfiction.net/story/#{@story_id}/"
        @epub_url = "https://www.fimfiction.net/story/download/#{@story_id}/epub"
      end

      def unpack
        unpack_globs ['*.html', 'book.opf']
      end

      def generate_config
        opf = Nokogiri::XML(File.open(@story_id + File::SEPARATOR + 'book.opf'))
        opf.remove_namespaces!
        date = DateTime.parse opf.at_xpath('/package/metadata/date').text

        chapters = Dir.glob(@story_id + File::SEPARATOR + 'chapter-*.html').
                     sort_by { |f| File.basename(f).split('-')[1].to_i }
        @conf = {
          'story' => {
            'year'     => date.year,
            'id'       => @story_id,
            'url'      => @epub_url,
            'epub'     => @filename,
            'metadata' => @story_id + File::SEPARATOR + 'title.html',
            'chapters' => (chapters.map { |file| { 'html' => file } }).
                            each_with_index { |chapter, index| chapter['number'] = index + 1 }
          }
        }
      end
    end
  end
end
