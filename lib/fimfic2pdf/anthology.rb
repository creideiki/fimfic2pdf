# frozen_string_literal: true

require 'logger'
require 'stringio'
require 'yaml'

require 'fimfic2pdf/template'

module FiMFic2PDF
  # Writes LaTex boilerplate for an anthology
  class Anthology
    attr_accessor :conf

    def initialize(options, mod)
      @mod = mod
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
      tmpl = @mod::Template.new
      File.open('template.tex', 'wb') do |f|
        f.write tmpl.style
        f.write tmpl.chapter_style(@options.chapter_style)
        f.write tmpl.select_hr(@options.hr_style, @options.hr_symbol)
        f.write tmpl.select_underline(@options.underline)
      end
      File.open('anthology.tex', 'wb') do |f|
        f.write "\\input{template}\n"
        titles = @conf.map { |story| story['title'] }.join ', '
        authors = @conf.map { |story| story['author'] }.uniq.join ', '
        f.write tmpl.header({ 'title'  => titles,
                              'author' => authors })
        f.write tmpl.toc if @options.toc
        f.write tmpl.body
        @conf.each do |story|
          if @conf.all? { |story| story['author'] == @conf[0]['author'] }
            f.write "\n\n\\part{#{story['title']}}"
          else
            f.write "\n\n\\partauthor[#{story['title']}]{#{story['title']}}[]{#{story['author']}}{}[]"
          end
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
