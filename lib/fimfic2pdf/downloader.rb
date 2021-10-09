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
      @logger = Logger.new($stderr)
      @logger.debug "Preparing to download story #{@story_id}"
      @url = "https://www.fimfiction.net/story/download/#{@story_id}/epub"
      @dir = story_id.to_s
      @logger.debug "Creating working directory #{@dir}"
      Dir.mkdir @dir unless File.directory? @dir
    end

    def fetch
      @logger.debug "Fetching EPUB from #{@url}"
      response = HTTParty.get(@url)
      raise "Failed to download #{@url}: #{response.code} #{response.message}" unless response.code == 200

      name = response.headers['content-disposition'].split('"')[1]
      @logger.debug "File name: #{name}"
      raise "Failed to parse filename: #{response.headers['content-disposition']}" unless name

      @filename = @dir + File::SEPARATOR + name

      File.open(@filename, 'wb') do |f|
        f.write response.body
      end
    end

    def unpack
      @logger.debug "Unpacking #{@filename}"
      epub = Zip::File.new(@filename)
      epub.glob('*.html').each do |entry|
        @logger.debug "Extracting #{entry.name}"
        File.open(@dir + File::SEPARATOR + entry.name, 'wb') do |f|
          f.write entry.get_input_stream.read
        end
      end
    end

    def generate_config
      @conf = {
        'story' => {
          'id' => @story_id,
          'url' => @url,
          'epub' => @filename,
          'metadata' => @dir + File::SEPARATOR + 'title.html',
          'chapters' =>
          Dir.glob(@dir + File::SEPARATOR + 'chapter-*.html').map do |file|
            { 'html' => file }
          end
        }
      }
    end

    def write_config
      @logger.debug 'Writing configuration from downloader'
      generate_config if not @conf
      File.open(@dir + File::SEPARATOR + 'config.yaml', 'wb') do |f|
        f.write YAML.dump @conf
      end
    end
  end
end
