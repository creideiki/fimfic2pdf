# frozen_string_literal: true

require 'logger'
require 'stringio'
require 'yaml'

require 'fimfic2pdf/template'

module FimFic2PDF
  # Writes LaTex boilerplate for an anthology
  class Anthology
    attr_accessor :conf

    def initialize(options)
      @options = options
      @logger = Logger.new($stderr, progname: 'Anthology')
      @logger.debug 'Preparing to compile anthology'
      @conf = []
      @options.ids.each do |id|
        story_conf = YAML.safe_load_file(id + File::SEPARATOR + 'config.yaml')['story']
        story = {
          'id'        => id,
          'title'     => story_conf['title'],
          'author'    => story_conf['author'],
          'filenames' => story_conf['volumes'].map { |v| v['filename'] }
        }
        @conf << story
      end
    end

    def write_anthology
      @logger.debug 'Writing LaTeX files for anthology'
      tmpl = FimFic2PDF::Template.new
      File.open('template.tex', 'wb') do |f|
        f.write tmpl.style
        f.write tmpl.chapter_style(@options.chapter_style)
        f.write tmpl.select_hr(@options.hr_style, @options.hr_symbol)
        f.write tmpl.select_underline(@options.underline)
      end
      File.open('anthology.tex', 'wb') do |f|
        f.write "\\input{template}\n"
        f.write tmpl.header
        f.write tmpl.toc if @options.toc
        f.write tmpl.body
        @conf.each do |story|
          f.write "\n\n\\part{#{story['title']}}"
          f.write "\n\\setcounter{chapter}{0}"
          story['filenames'].each do |file|
            f.write "\n\\subimport{#{File::dirname file}}{#{(File::basename file).sub('.tex', '-chapters')}}"
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
