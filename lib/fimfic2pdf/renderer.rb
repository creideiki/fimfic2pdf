# frozen_string_literal: true

require 'English'
require 'logger'
require 'yaml'

module FiMFic2PDF
  # Calls LaTeX to render the story into PDF format.
  class Renderer
    attr_accessor :conf, :filename, :url

    # Return the name of the LaTeX interpreter to use.
    # def tex_program() end

    # Return the number of LaTeX passes to run.
    # def num_passes() end

    def initialize(story_id)
      @story_id = story_id
      @logger = Logger.new($stderr, progname: 'Renderer')
      @logger.debug "Preparing to render story #{@story_id}"
      @config_file = @story_id + File::SEPARATOR + 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
    end

    def render_volume(num)
      @logger.debug "Rendering volume #{num + 1}"

      num_passes.times do |pass|
        @logger.debug "Running render pass #{pass + 1}"
        system(tex_program, File.basename(@conf['story']['volumes'][num]['tex_file']),
               chdir: @story_id, exception: true)
      end

      @logger.debug 'Rendering completed'
    end

    def render_story # rubocop:disable Metrics/AbcSize
      @conf['story']['volumes'].each_index { |num| render_volume num }

      @conf['story']['volumes'].each do |vol|
        @logger.info "Finished PDF: #{vol['pdf_file']}"
      end

      @conf['story']['volumes'].each_with_index do |vol, num|
        pages = 0
        File.open(vol['aux_file']) do |f|
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
  end
end
