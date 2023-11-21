# frozen_string_literal: true

require 'fimfic2pdf/driver'

module FiMFic2PDF
  module Book
    # A CLI application
    class Driver < FiMFic2PDF::Driver
      def initialize(progname, mod) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        super

        @options = OpenStruct.new({
                                    anthology_title: 'Anthology',
                                    authors_notes: :remove,
                                    barred_blockquotes: false,
                                    hr_style: :asterism,
                                    ids: [],
                                    prettify_quotes: false,
                                    prettify_single_quotes: false,
                                    toc: true,
                                    underline: :fancy
                                  })

        @description = '
Transforms a fanfiction story into PDF using the "book" LaTeX class.

The "book" class is more flexible than the "novel" class, allowing
more formatting that is not traditionally used in fiction books, but
may produce worse-looking output.

Saves files in a working directory named ./<ID>/.

If the story is inaccessible to an anonymous guest, because it can
only be read when logged in, you can download the epub file manually
through your web browser and save it as `./<ID>/<ID>.epub`.

If multiple IDs specified, writes an anthology in the current working
directory consisting of the identified stories.

When run multiple times:

* By default, only re-renders the PDF, including any manual changes
  made to the generated LaTeX code.
* To re-parse the HTML and re-transform to LaTeX, losing any manual
  changes, use the "-t/--retransform" flag.
* To re-unpack the EPUB file and start over, remove the file
  ./<ID>/config.yaml.

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

To attempt to automatically change ASCII single quotes to Unicode
ones, use the "-p/--prettify-single-quotes" option. This will attempt
to detect and skip those that are apostrophes, but this is brittle and
not likely to produce a good result on the first pass. You will
probably need to inspect the PDF output, see where the automatic
detection first failed, and manually change that ASCII single quote to
a Unicode one in the HTML source to get the automation back on track.

Author\'s note sections at the end of each chapter are removed by
default. To include them, use the "-n/--authors-notes" option to
specify their style.

If the source text contains Unicode en and em dashes, they will be
rendered correctly. If it only contains ASCII hyphens, they will be
rendered as hyphens, which is probably not the intended outcome. Since
the intended character cannot be automatically determined, you will
have to fix this manually. If you cannot write Unicode dashes
directly, you can edit the LaTeX code and write "--" for an en dash
(–) and "---" for an em dash (—).'

        @parser.on('-b', '--barred-blockquotes',
                   'put vertical bars in the left margin of block quotes') do
          @options.barred_blockquotes = true
        end

        @parser.on('-c', '--no-chapter',
                   'disable "Chapter X" in chapter titles') do
          @options.chapter_style = :no_chapter
        end

        @parser.on('-n', '--authors-notes STYLE',
                   [:remove, :plain],
                   'handle author\'s notes: remove (default), plain') do |s|
          @options.authors_notes = s
        end

        @parser.on('-o', '--no-toc',
                   'disable table of contents') do
          @options.toc = false
        end

        @parser.on('-p', '--prettify-single-quotes',
                   'change ASCII single quotation marks to Unicode ones') do
          @options.prettify_single_quotes = true
        end

        @parser.on('-q', '--prettify-quotes',
                   'change ASCII quotation marks to Unicode ones') do
          @options.prettify_quotes = true
        end

        @parser.on('-s', '--hr-style STYLE',
                   [:asterism, :fleuron, :line, :scrollwork],
                   'style of <hr> section breaks: asterism (default), fleuron, line, or scrollwork') do |s|
          @options.hr_style = s
        end

        @parser.on('-u', '--underline STYLE',
                   [:fancy, :simple, :italic, :regular],
                   'how to render underlined text: fancy (default), simple, italic, or regular') do |s|
          @options.underline = s
        end

        @parser.on('-v CHAPTERS,CHAPTERS', '--volumes START1-END1,...',
                   'split story into multiple volumes', Array) do |volumes|
          @options.volumes = volumes
        end

        @parser.on('-y', '--hr-symbol SYMBOL', Integer,
                   'symbol number for scrollwork or fleuron') do |y|
          @options.hr_symbol = y
        end
      end

      def parse_arguments(args)
        super

        unless @options.hr_symbol # rubocop:disable Style/GuardClause
          @options.hr_symbol = 82  if @options.hr_style == :scrollwork
          @options.hr_symbol = 108 if @options.hr_style == :fleuron
        end
      end
    end
  end
end
