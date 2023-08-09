# frozen_string_literal: true

require 'logger'
require 'stringio'
require 'yaml'

require 'fimfic2pdf/template'

module FiMFic2PDF
  # Writes LaTex boilerplate for an anthology
  class Anthology
    attr_accessor :conf

    def initialize(options, mod) # rubocop:disable Metrics/AbcSize
      @mod = mod
      @options = options
      @logger = Logger.new($stderr, progname: 'Anthology')
      @logger.debug 'Preparing to compile anthology'
      @conf = {
        'anthology' => {
          'title'   => @options.anthology_title,
          'stories' => []
        }
      }
      @options.ids.each do |id|
        story_conf = YAML.safe_load_file(id + File::SEPARATOR + 'config.yaml')['story']
        story = {
          'id'        => id,
          'title'     => story_conf['title'],
          'author'    => story_conf['author'],
          'tex_files' => story_conf['volumes'].map { |v| v['tex_file'] }
        }
        @conf['anthology']['stories'] << story
      end
      @conf['anthology']['author'] = @conf['anthology']['stories'].map { |s| s['author'] }.uniq.join ', '
    end

    # Return LaTeX code for drawing an interstitial page before each
    # story.
    # def interstitial(title, author = nil) end

    def write_anthology
      @logger.debug 'Writing LaTeX files for anthology'
      tmpl = @mod::Template.new
      File.open('template.tex', 'wb') do |f|
        f.write tmpl.style
        f.write tmpl.chapter_style(@options.chapter_style)
        f.write tmpl.select_hr(@options.hr_style, @options.hr_symbol)
        f.write tmpl.select_underline(@options.underline)
      end
      File.open('anthology.tex', 'wb') do |f|
        f.write "\\input{template}\n"
        f.write tmpl.header({ 'title'  => @conf['anthology']['title'],
                              'author' => @conf['anthology']['author'] })
        f.write tmpl.front_matter(@conf['anthology'], 1) if @options.front_matter
        f.write tmpl.toc if @options.toc
        f.write tmpl.body
        @conf['anthology']['stories'].each do |story|
          if @conf['anthology']['stories'].all? { |story| story['author'] == @conf['anthology']['author'] }
            f.write interstitial(story['title'])
          else
            f.write interstitial(story['title'], story['author'])
          end
          story['tex_files'].each do |file|
            f.write "\n\\subimport{#{File::dirname file}}{vol1-chapters}"
          end
        end
        f.write tmpl.footer
      end
    end

    def write_config
      @logger.debug 'Writing configuration from anthology'
      File.binwrite('config.yaml', YAML.dump(@conf))
    end
  end
end
