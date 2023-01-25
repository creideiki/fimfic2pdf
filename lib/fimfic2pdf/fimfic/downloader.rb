# frozen_string_literal: true

require 'fimfic2pdf/downloader'

module FimFic2PDF
  module FiMFic
    # Fetches and unpacks EPUB archives from FiMFiction
    class Downloader < FimFic2PDF::Downloader
      def initialize(story_id)
        super
        @story_url = "https://www.fimfiction.net/story/#{@story_id}/"
        @epub_url = "https://www.fimfiction.net/story/download/#{@story_id}/epub"
      end

      def unpack
        unpack_globs ['*.html']
      end

      def generate_config
        chapters = Dir.glob(@story_id + File::SEPARATOR + 'chapter-*.html').
                     sort_by { |f| File.basename(f).split('-')[1].to_i }
        @conf = {
          'story' => {
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
