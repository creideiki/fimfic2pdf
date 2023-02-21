# frozen_string_literal: true

require 'fimfic2pdf/driver'

module FiMFic2PDF
  module Novel
    # A CLI application
    class Driver < FiMFic2PDF::Driver
      def initialize(progname, mod) # rubocop:disable Metrics/MethodLength
        super

        @options = OpenStruct.new({
                                    authors_notes: :remove,
                                    barred_blockquotes: false,
                                    hr_style: :scenestars,
                                    ids: [],
                                    toc: false,
                                    underline: :italic
                                  })

        @parser.banner = "Usage: #{progname} -i ID[,ID...] [options]"

        @description = '
Transforms a fanfiction story into PDF using the "novel" LaTeX class.

The "novel" class is less flexible than the "book" class, and requires
more manual checking, but may produce better-looking output if your
formatting fits.

Documentation for the "novel" class can be found at
   https://ctan.org/pkg/novel

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
   --hr-style [asterism,scenebreak,sceneline,scenestars]
where "scenestars" is the default.

Asterism is three asterisks in a triangle, scenebreak a blank line,
sceneline a short horizontal line, and scenestars three asterisks in a
line.

Underlined text cannot be typeset by the "novel" class, so it is
switched to italic.

If the source text contains Unicode open/close quotation marks, they
will be rendered correctly by default. If it only contains ASCII
straight quotation marks, they will all be rendered as closing
quotation marks by default. To attempt to automatically change ASCII
quotation marks to Unicode ones, use the "-q/--prettify-quotes"
option. This will blindly change every straight double quote to an
alternating open or close one, which will fail silently if quotes are
not strictly balanced. It also will not handle single quotes, since
those are indistinguishable from apostrophes.

If the source text contains Unicode en and em dashes, they will be
rendered correctly. If it only contains ASCII hyphens, they will be
rendered as hyphens, which is probably not the intended outcome. Since
the intended character cannot be automatically determined, you will
have to fix this manually. If you cannot write Unicode dashes
directly, you can edit the LaTeX code and write "--" for an en dash
(–) and "---" for an em dash (—).

For short snippets of text in another language, add a block like this
to "template.tex":
   \setotherlanguage{arabic}
   \newfontfamily\arabicfont[Script=Arabic]{Amiri}
and wrap the foreign text as
   \textarabic{arabic text goes here}
.

When changing font sizes, the "novel" class handles short snippets
with small changes better than "book", but longer passages or large
changes are discouraged. To typeset an entire paragraph in a different
font size, which may mitigate some issues, change the automatic
output:
   \charscale[2]{This is }\charscale[2]{\textit{SHOUTING}}
to
   \begin{parascale}[2]This is \textit{SHOUTING}\end{parascale}
'

        @parser.on('-q', '--prettify-quotes',
                   'change ASCII quotation marks to Unicode ones') do
          @options.prettify_quotes = true
        end

        @parser.on('-s', '--hr-style STYLE',
                   [:asterism, :scenebreak, :sceneline, :scenestars],
                   'style of <hr> section breaks: asterism, scenebreak, sceneline, or scenestars (default)') do |s|
          @options.hr_style = s
        end

        @parser.on('-v CHAPTERS,CHAPTERS', '--volumes START1-END1,...',
                   'split story into multiple volumes', Array) do |volumes|
          @options.volumes = volumes
        end
      end
    end
  end
end
