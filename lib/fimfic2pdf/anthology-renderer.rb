# frozen_string_literal: true

require 'English'
require 'logger'
require 'yaml'

module FimFic2PDF
  # Calls LaTeX to render the story into PDF format.
  class Anthology_Renderer
    attr_accessor :conf, :filename, :url

    def initialize
      @logger = Logger.new($stderr, progname: 'Anthology renderer')
      @logger.debug 'Preparing to render anthology'
      @config_file = 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
    end

    def render_anthology
      @logger.debug 'Rendering anthology'

      @logger.debug 'Running first render pass'
      system('xelatex', 'anthology.tex', exception: true)

      @logger.debug 'Running second render pass'
      system('xelatex', 'anthology.tex', exception: true)

      @logger.debug 'Running third render pass'
      system('xelatex', 'anthology.tex', exception: true)

      @logger.debug 'Rendering completed'

      @logger.info 'Finished PDF: anthology.pdf'

      pages = 0
      File.open('anthology.aux') do |f|
        page_number_regexp = /abspage@last\{(?<pages>[[:digit:]]+)}$/
        f.each_line do |line|
          page_number_regexp.match(line) do |m|
            pages = m['pages'].to_i
          end
        end
      end

      @logger.debug "Anthology has #{pages} pages."
      if pages >= 400
        @logger.info "Anthology has #{pages} pages. Consider splitting it into multiple volumes for printing."
      end
    end
  end
end
