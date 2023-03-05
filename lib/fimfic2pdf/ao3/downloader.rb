# frozen_string_literal: true

require 'date'
require 'nokogiri'
require 'uri'

require 'fimfic2pdf/downloader'

module FiMFic2PDF
  module AO3
    # Fetches and unpacks EPUB archives from AO3
    class Downloader < FiMFic2PDF::Downloader
      def initialize(story_id)
        super
        @story_url = "https://archiveofourown.org/works/#{@story_id}/"
      end

      def fetch
        @logger.debug "Fetching story from #{@story_url}"
        response = HTTParty.get(@story_url,
                                headers: {
                                  'User-Agent' => "FiMFic2PDF/#{FiMFic2PDF::VERSION}"
                                })
        raise "Failed to download #{@url}: #{response.code} #{response.message}" unless response.code == 200

        doc = Nokogiri::HTML(response.body)
        @epub_url = 'https://archiveofourown.org' + # rubocop:disable Style/StringConcatenation
                    doc.at_xpath('//a[contains(@href, ".epub?")]')['href']

        super
      end

      def unpack
        unpack_globs ['toc.ncx', 'content.opf', '*.xhtml']
      end

      def generate_config
        toc = Nokogiri::XML(File.open(@story_id + File::SEPARATOR + 'toc.ncx'))
        toc.remove_namespaces!
        chapters = toc.xpath('//navPoint').sort_by { |p| p['playOrder'].to_i }
        # First segment is tags and summary, last segment is author's notes
        chapters = chapters[1..-2]

        opf = Nokogiri::XML(File.open(@story_id + File::SEPARATOR + 'content.opf'))
        opf.remove_namespaces!
        date = DateTime.parse opf.at_xpath('/package/metadata/date').text

        p = URI::Parser.new

        @conf = {
          'story' => {
            'year'     => date.year,
            'id'       => @story_id,
            'url'      => @story_url,
            'epub'     => @filename,
            'metadata' => @story_id + File::SEPARATOR + 'content.opf',
            'chapters' => chapters.map do |c|
              {
                'html'   => @story_id + File::SEPARATOR +
                            p.unescape(c.at_xpath('content')['src']), # rubocop:disable Layout/MultilineOperationIndentation
                'number' => c['playOrder'].to_i - 1,
                'title'  => c.at_xpath('navLabel').text.strip
              }
            end
          }
        }
      end
    end
  end
end
