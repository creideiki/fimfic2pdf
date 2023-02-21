# frozen_string_literal: true

require 'logger'
require 'optparse'
require 'ostruct'

module FiMFic2PDF
  # A CLI application
  class Driver
    def initialize(progname, mod) # rubocop:disable Metrics/AbcSize
      @logger = Logger.new($stderr, progname: 'Driver')

      @mod = mod
      @parser = OptionParser.new

      @parser.banner = "Usage: #{progname} -i ID[,ID...] [options]"

      @description = 'Default FiMFic2PDF driver program.'

      @parser.separator 'Main options'
      @parser.separator ''
      @parser.on('-i ID,ID,...', '--id ID,ID,...', 'story ID(s)', Array) do |ids|
        ids.each do |id|
          m = /(?<id>[[:digit:]]+)/.match id
          @options.ids << m['id'] if m
        end
      end
      @parser.on('-t', '--retransform',
                 're-parse the HTML and re-transform to LaTeX, losing manual changes') do |f|
        @options.force_retransform = f
      end

      @parser.separator ''

      @parser.on('-V', '--version', 'display version information') do
        puts "FiMFic2PDF #{FiMFic2PDF::VERSION}"
        exit 0
      end

      @parser.on('-h', '--help', 'display usage information') do
        abort(@parser.to_s + @description)
      end

      @parser.separator ''
      @parser.separator 'Formatting options'
      @parser.separator 'Changing these have no effect unless also specifying "-t/--retransform", losing manual changes'
      @parser.separator ''
    end

    def parse_arguments(args)
      begin
        @parser.parse! args
      rescue OptionParser::ParseError => e
        if e.args.empty?
          abort @parser.to_s
        else
          abort "#{e}\n\n#{@parser}"
        end
      end

      unless @options.ids.size.positive? # rubocop:disable Style/GuardClause
        puts 'No story ID(s) specified.'
        puts ''
        abort @parser.to_s
      end
    end

    def download
      @options.ids.each do |id|
        if File.directory? id
          @logger.info "Working directory #{id} already exists, not downloading EPUB"
        else
          downloader = @mod::Downloader.new id
          downloader.fetch
          downloader.unpack
          downloader.write_config
          @options.transform = true
        end
      end
    end

    def transform
      @warnings = {}

      @options.ids.each do |id|
        @options.id = id

        if @options.force_retransform or @options.transform
          if @options.force_retransform
            @logger.info 'Forcing reparse and retransform from HTML to LaTeX due to "-t" flag'
          end
          transformer = @mod::Transformer.new @options
          transformer.validate_volumes
          transformer.parse_metadata
          @warnings = transformer.transform
          transformer.write_story
          transformer.write_config
        else
          @logger.info 'Not transforming, using existing LaTeX code'
        end
      end

      if @options.ids.size > 1 # rubocop:disable Style/GuardClause
        @logger.debug 'Writing anthology top level document'
        anthology = @mod::Anthology.new(@options, @mod)
        anthology.write_anthology
        anthology.write_config
      end
    end

    def render
      if @options.ids.size > 1
        @logger.debug 'Rendering anthology'
        renderer = @mod::AnthologyRenderer.new
        renderer.render_anthology
      else
        @logger.debug 'Rendering single story'
        renderer = @mod::Renderer.new @options.id
        renderer.render_story
      end
    end

    def warn
      @warnings.each do |_type, warn|
        unless warn[:chapters].empty?
          @logger.warn warn[:message]
          warn[:chapters].each { |c| @logger.warn c }
        end
      end
    end

    def run
      @options.template = @mod::Template
      parse_arguments(ARGV)
      download
      transform
      render
      warn
    end
  end
end
