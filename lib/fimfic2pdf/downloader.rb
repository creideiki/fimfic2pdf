# frozen_string_literal: true

require 'httparty'
require 'logger'
require 'yaml'
require 'zip'

module FiMFic2PDF
  # Fetches EPUB archives from fimfiction.net
  class Downloader
    attr_accessor :conf, :filename, :url

    def initialize(story_id)
      @story_id = story_id
      @logger = Logger.new($stderr, progname: 'Downloader')
      @logger.debug "Preparing to download story #{@story_id}"
      @logger.debug "Creating working directory #{@story_id}"
      Dir.mkdir @story_id unless File.directory? @story_id
    end

    def manually_downloaded?
      manual_filename = @story_id + File::SEPARATOR + @story_id + '.epub'
      @logger.debug "Checking if EPUB has been downloaded manually to #{manual_filename}"
      if File.readable? manual_filename
        @filename = manual_filename
        @logger.debug 'Manual download found'
        true
      else
        @logger.debug 'Not found, will download'
        false
      end
    end

    def fetch
      @logger.debug "Fetching EPUB from #{@epub_url}"
      response = HTTParty.get(@epub_url,
                              headers: {
                                'User-Agent' => "FiMFic2PDF/#{FiMFic2PDF::VERSION}"
                              })
      raise "Failed to download #{@epub_url}: #{response.code} #{response.message}" unless response.code == 200

      name = response.headers['content-disposition'].split('"')[1]
      @logger.debug "File name: #{name}"
      raise "Failed to parse filename: #{response.headers['content-disposition']}" unless name

      @filename = @story_id + File::SEPARATOR + name

      File.binwrite(@filename, response.body)
    end

    def unpack_globs(globs)
      @logger.debug "Unpacking #{@filename}"
      epub = Zip::File.new(@filename)
      globs.each do |glob|
        epub.glob(glob).each do |entry|
          @logger.debug "Extracting #{entry.name}"
          File.binwrite(@story_id + File::SEPARATOR + entry.name,
                        entry.get_input_stream.read)
        end
      end
    end

    # Unpack HTML files and any required metadata files from the
    # downloaded epub file.
    # def unpack() end

    # Generate configuration in the @conf variable.
    # def generate_config(parser) end

    def write_config
      @logger.debug 'Writing configuration from downloader'
      generate_config if not @conf
      File.binwrite(@story_id + File::SEPARATOR + 'config.yaml', YAML.dump(@conf))
    end
  end
end
