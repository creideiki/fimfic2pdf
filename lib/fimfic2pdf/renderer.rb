# frozen_string_literal: true

require 'English'
require 'logger'
require 'yaml'

module FimFic2PDF
  # Calls LaTeX to render the story into PDF format.
  class Renderer
    attr_accessor :conf, :filename, :url

    def initialize(story_id)
      @story_id = story_id
      @logger = Logger.new($stderr, progname: 'Renderer')
      @logger.debug "Preparing to render story #{@story_id}"
      @dir = story_id.to_s
      @config_file = @dir + File::SEPARATOR + 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
    end

    def render_volume(num)
      @logger.debug "Rendering volume #{num + 1}"

      @logger.debug 'Running first render pass'
      system('xelatex', "vol#{num + 1}.tex", chdir: @dir, exception: true)

      @logger.debug 'Running second render pass'
      system('xelatex', "vol#{num + 1}.tex", chdir: @dir, exception: true)

      @logger.debug 'Running third render pass'
      system('xelatex', "vol#{num + 1}.tex", chdir: @dir, exception: true)

      @logger.debug 'Running fourth render pass'
      system('xelatex', "vol#{num + 1}.tex", chdir: @dir, exception: true)

      @logger.debug 'Rendering completed'
    end

    # rubocop:disable Style/CombinableLoops
    def render_story # rubocop:disable Metrics/AbcSize
      @conf['story']['volumes'].each_index { |num| render_volume num }

      @conf['story']['volumes'].each_index do |num|
        @logger.info "Finished PDF: #{@dir}#{File::SEPARATOR}vol#{num + 1}.pdf"
      end

      @conf['story']['volumes'].each_index do |num|
        pages = 0
        File.open(@dir + File::SEPARATOR + "vol#{num + 1}.aux") do |f|
          page_number_regexp = /abspage@last\{(?<pages>[[:digit:]]+)}$/
          f.each_line do |line|
            page_number_regexp.match(line) do |m|
              pages = m['pages'].to_i
            end
          end
        end

        @logger.debug "Volume #{num + 1} has #{pages} pages."
        if pages >= 400
          @logger.info "Volume #{num + 1} has #{pages} pages. Consider splitting it into multiple volumes for printing."
        end
      end
    end
    # rubocop:enable Style/CombinableLoops
  end
end
