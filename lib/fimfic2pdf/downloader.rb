# frozen_string_literal: true

require 'httparty'
require 'logger'
require 'yaml'
require 'zip'

module FimFic2PDF
  # Fetches EPUB archives from fimfiction.net
  class Downloader
    attr_accessor :conf, :filename, :url

    def initialize(story_id)
      @story_id = story_id
      @logger = Logger.new($stderr, progname: 'Downloader')
      @logger.debug "Preparing to download story #{@story_id}"
      @url = "https://www.fimfiction.net/story/download/#{@story_id}/epub"
      @logger.debug "Creating working directory #{@story_id}"
      Dir.mkdir @story_id unless File.directory? @story_id
    end

    def fetch
      @logger.debug "Fetching EPUB from #{@url}"
      response = HTTParty.get(@url,
                              headers: {
                                'User-Agent' => "FimFic2PDF/#{FimFic2PDF::VERSION}"
                              })
      raise "Failed to download #{@url}: #{response.code} #{response.message}" unless response.code == 200

      name = response.headers['content-disposition'].split('"')[1]
      @logger.debug "File name: #{name}"
      raise "Failed to parse filename: #{response.headers['content-disposition']}" unless name

      @filename = @story_id + File::SEPARATOR + name

      File.binwrite(@filename, response.body)
    end

    def unpack
      @logger.debug "Unpacking #{@filename}"
      epub = Zip::File.new(@filename)
      epub.glob('*.html').each do |entry|
        @logger.debug "Extracting #{entry.name}"
        File.binwrite(@story_id + File::SEPARATOR + entry.name,
                      entry.get_input_stream.read)
      end
    end

    def generate_config
      chapters = Dir.glob(@story_id + File::SEPARATOR + 'chapter-*.html').
                 sort_by { |f| File.basename(f).split('-')[1].to_i }
      @conf = {
        'story' => {
          'id'       => @story_id,
          'url'      => @url,
          'epub'     => @filename,
          'metadata' => @story_id + File::SEPARATOR + 'title.html',
          'chapters' => (chapters.map { |file| { 'html' => file } }).
              each_with_index { |chapter, index| chapter['number'] = index + 1 }
        }
      }
    end

    def write_config
      @logger.debug 'Writing configuration from downloader'
      generate_config if not @conf
      File.binwrite(@story_id + File::SEPARATOR + 'config.yaml', YAML.dump(@conf))
    end
  end
end
