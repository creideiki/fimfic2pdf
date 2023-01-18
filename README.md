# FimFic2PDF

Renders stories from [FiMFiction](https://www.fimfiction.net/) as PDF.

## Requirements

* [Ruby 3](https://www.ruby-lang.org/en/)
  * [httparty](https://www.johnnunemaker.com/httparty/)
  * [nokogiri](https://nokogiri.org/)
  * [rubyzip](https://rubygems.org/gems/rubyzip)
* [xelatex](https://en.wikipedia.org/wiki/XeTeX)

## Installation

```sh
gem build fimfic2pdf.gemspec
gem install ./fimfic2pdf-*.gem
```

## Basic usage

Run `fimfic2pdf -i LINK`, where `LINK` is a link to the story's page
on FiMFiction.

A whole lot of output will be generated, which you don't need to care
about unless something goes wrong.

The second to last line printed will tell you that the PDF was saved
as `ID/vol1.pdf`, where `ID` is the numbers in the URL after
`https://www.fimfiction.net/story/`. You can also use just this ID
when running the program instead of the entire link.

The default format uses 6x9" paper and includes a table of contents.

## Advanced usage

```
Usage: fimfic2pdf -i ID[,ID...] [options]

Main options

    -i, --id ID,ID,...               story ID(s)
    -t, --retransform                re-parse the HTML and re-transform to LaTeX, losing manual changes

    -V, --version                    display version information
    -h, --help                       display usage information

Formatting options
Changing these have no effect unless also specifying "-t/--retransform", losing manual changes

    -a, --authors-notes STYLE        handle author's notes: remove (default), plain
    -b, --barred-blockquotes         put vertical bars in the left margin of block quotes
    -c, --no-chapter                 disable "Chapter X" in chapter titles
    -o, --no-toc                     disable table of contents
    -q, --prettify-quotes            change ASCII quotation marks to Unicode ones
    -s, --hr-style STYLE             style of <hr> section breaks: asterism (default), fleuron, or scrollwork
    -u, --underline STYLE            how to render underlined text: fancy (default), simple, italic, or regular
    -v, --volumes START1-END1,...    split story into multiple volumes
    -y, --hr-symbol SYMBOL           symbol number for scrollwork or fleuron

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
   --hr-style [asterism,fleuron,scrollwork]
where "asterism" is the default.

Asterism is three asterisks in a triangle.

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

Author's note sections at the end of each chapter are removed by
default. To include them, use the "-a/--authors-notes" option to
specify their style.

If the source text contains Unicode en and em dashes, they will be
rendered correctly. If it only contains ASCII hyphens, they will be
rendered as hyphens, which is probably not the intended outcome. Since
the intended character cannot be automatically determined, you will
have to fix this manually. If you cannot write Unicode dashes
directly, you can edit the LaTeX code and write "--" for an en dash
(–) and "---" for an em dash (—).
```

`fimfic2pdf` will create a directory with the story ID as name, download the EPUB version of the story to that directory, unpack it to HTML, parse the HTML, transform it to LaTeX, and run `xelatex` to generate a PDF.

If called with multiple story IDs, it will also write a LaTeX file that collects them into an anthology in the current working directory, and run `xelatex` on it instead.

If you change any formatting options and want to rerun transformation with the new options, use the `-t` flag.

If you want to change the rendering, edit the generated files and run `fimfic2pdf` again. It will notice that the files are already downloaded and just rerun `xelatex` to include your edits.

To redo the entire process, including downloading the EPUB file, delete the working directory and run `fimfic2pdf` again.
