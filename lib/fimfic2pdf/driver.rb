#!/usr/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'optparse'
require 'ostruct'

require 'fimfic2pdf'

module FimFic2PDF
  # A CLI application
  class Driver
    def initialize(progname, mod) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @logger = Logger.new($stderr, progname: 'Driver')

      @mod = mod
      @parser = OptionParser.new
      @options = OpenStruct.new({
                                  authors_notes: :remove,
                                  hr_style: :asterism,
                                  ids: [],
                                  toc: true,
                                  underline: :fancy
                                })

      @parser.banner = "Usage: #{progname} -i ID[,ID...] [options]"

      @description = '
Saves files in a working directory named ./<ID>/.

If multiple IDs specified, writes an anthology in the current working
directory consisting of the identified stories.

When run multiple times:

* By default, only re-renders the PDF, including any manual changes
  made to the generated LaTeX code.
* To re-parse the HTML and re-transform to LaTeX, losing any manual
  changes, use the "-t/--retransform" flag.
* To re-download the EPUB file and start over, remove the ./<ID>/
  directory.

To change any formatting options, "-t/--retransform" must be
specified, which loses any manual changes.

By default, produces a single PDF with all chapters. For splitting
into mutiple volumes, give the range of chapters for each volume,
e.g.:
   --volumes 1-10,11-20
yields two volumes, containing chapters 1-10 and 11-20, respectively.
Each chapter must be used in exactly one volume.

Section breaks (represented as a horizontal line in EPUB and lines
with asterisks on the web) have a few different renderings. To choose
a style, use:
   --hr-style [asterism,fleuron,line,scrollwork]
where "asterism" is the default.

Asterism is three asterisks in a triangle. Line is a plain horizontal
line.

Fleuron (centered, roughly square symbol) and scrollwork (horizontally
extended line with flourishes) take a number specifying which symbol
to use. See the "pgfornament" documentation at
https://ctan.org/pkg/pgfornament for the complete list. 80-89 are
recommended for scrollwork and the rest for fleurons. The default is a
horse for fleurons (symbol 108) and a line with a center embellishment
for scrollwork (symbol 82).

Underlined text cannot be automatically broken into lines. A list of
chapters containing underlined text will be printed, so it can be
checked manually for overruns. To break a line of underlined text, end
and then restart the \fancyuline{} environment. E.g. change:
   \fancyuline{This is a long line that should be broken.}
into
   \fancyuline{This is a long line} \fancyuline{that should be broken.}
Then re-run the program (without specifying "-t/--retransform") to
re-render the changed LaTeX code.

To avoid this problem with the default underlines, alternative styles
may be used instead of underlining. Use the "-u/--underline" option to
specify which style to use:

   fancy: default, leaves gaps around descenders, no line breaks
   simple: handles line breaks but no additional formatting
   italic: render underlined text as italics instead
   regular: render underlined text as regular text

If the source text contains Unicode open/close quotation marks, they
will be rendered correctly by default. If it only contains ASCII
straight quotation marks, they will all be rendered as closing
quotation marks by default. To attempt to automatically change ASCII
quotation marks to Unicode ones, use the "-q/--prettify-quotes"
option. This will blindly change every straight double quote to an
alternating open or close one, which will fail silently if quotes are
not strictly balanced. It also will not handle single quotes, since
those are indistinguishable from apostrophes.

Author\'s note sections at the end of each chapter are removed by
default. To include them, use the "-a/--authors-notes" option to
specify their style.

If the source text contains Unicode en and em dashes, they will be
rendered correctly. If it only contains ASCII hyphens, they will be
rendered as hyphens, which is probably not the intended outcome. Since
the intended character cannot be automatically determined, you will
have to fix this manually. If you cannot write Unicode dashes
directly, you can edit the LaTeX code and write "--" for an en dash
(–) and "---" for an em dash (—).'

      @parser.separator ''

      # rubocop:disable Layout/LineLength
      @parser.separator 'Main options'
      @parser.separator ''
      @parser.on('-i ID,ID,...', '--id ID,ID,...', 'story ID(s)', Array) do |ids|
        ids.each do |id|
          m = /(?<id>[[:digit:]]+)/.match id
          @options.ids << m['id'] if m
        end
      end
      @parser.on('-t', '--retransform', 're-parse the HTML and re-transform to LaTeX, losing manual changes') { |f| @options.force_retransform = f }

      @parser.separator ''
      @parser.on('-V', '--version', 'display version information') do
        puts "FimFic2PDF #{FimFic2PDF::VERSION}"
        exit 0
      end
      @parser.on('-h', '--help', 'display usage information') { abort(@parser.to_s + @description) }

      @parser.separator ''
      @parser.separator 'Formatting options'
      @parser.separator 'Changing these have no effect unless also specifying "-t/--retransform", losing manual changes'
      @parser.separator ''

      @parser.on('-a', '--authors-notes STYLE', [:remove, :plain], 'handle author\'s notes: remove (default), plain') { |s| @options.authors_notes = s }
      @parser.on('-b', '--barred-blockquotes', 'put vertical bars in the left margin of block quotes') { @options.barred_blockquotes = true }
      @parser.on('-c', '--no-chapter', 'disable "Chapter X" in chapter titles') { @options.chapter_style = :no_chapter }
      @parser.on('-o', '--no-toc', 'disable table of contents') { @options.toc = false }
      @parser.on('-q', '--prettify-quotes', 'change ASCII quotation marks to Unicode ones') { @options.prettify_quotes = true }
      @parser.on('-s', '--hr-style STYLE', [:asterism, :fleuron, :line, :scrollwork], 'style of <hr> section breaks: asterism (default), fleuron, line, or scrollwork') { |s| @options.hr_style = s }
      @parser.on('-u', '--underline STYLE', [:fancy, :simple, :italic, :regular], 'how to render underlined text: fancy (default), simple, italic, or regular') { |s| @options.underline = s }
      @parser.on('-v CHAPTERS,CHAPTERS', '--volumes START1-END1,...', 'split story into multiple volumes', Array) { |volumes| @options.volumes = volumes }
      @parser.on('-y', '--hr-symbol SYMBOL', Integer, 'symbol number for scrollwork or fleuron') { |y| @options.hr_symbol = y }
      # rubocop:enable Layout/LineLength
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

      unless @options.ids.size.positive?
        puts 'No story ID(s) specified.'
        puts ''
        abort @parser.to_s
      end

      unless @options.hr_symbol # rubocop:disable Style/GuardClause
        @options.hr_symbol = 82  if @options.hr_style == :scrollwork
        @options.hr_symbol = 108 if @options.hr_style == :fleuron
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
        anthology = FimFic2PDF::Anthology.new @options
        anthology.write_anthology
        anthology.write_config
      end
    end

    def render
      if @options.ids.size > 1
        @logger.debug 'Rendering anthology'
        renderer = FimFic2PDF::AnthologyRenderer.new
        renderer.render_anthology
      else
        @logger.debug 'Rendering single story'
        renderer = FimFic2PDF::Renderer.new @options.id
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
      parse_arguments(ARGV)
      download
      transform
      render
      warn
    end
  end
end