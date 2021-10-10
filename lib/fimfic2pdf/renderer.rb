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
      @logger = Logger.new($stderr)
      @logger.debug "Preparing to render story #{@story_id}"
      @dir = story_id.to_s
      @config_file = @dir + File::SEPARATOR + 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
    end

    def render
      @logger.debug 'Running first render pass'
      res = system('xelatex', 'book.tex', :chdir => @dir)
      raise "Error running first render pass: #{$CHILD_STATUS}" unless res

      @logger.debug 'Running second render pass'
      res = system('xelatex', 'book.tex', :chdir => @dir)
      raise "Error running second render pass: #{$CHILD_STATUS}" unless res

      @logger.info 'Rendering completed'
    end
  end
end
