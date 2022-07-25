# FimFic2PDF

Renders stories from [FimFiction](https://www.fimfiction.net/) as PDF.

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

Find the story ID, which is the numbers in the URL after `https://www.fimfiction.net/story/`. Then, run `fimfic2pdf -i ID`. The PDF will be saved as `ID/vol1.pdf`.

The default format uses 6x9" paper and includes a table of contents.

## Advanced usage

```
Usage: fimfic2pdf -i ID [options]

Saves files in a working directory named ./<ID>/.

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

Main options

    -i, --id ID                      story ID
    -t, --retransform                re-parse the HTML and re-transform to LaTeX, losing manual changes

    -V, --version                    display version information
    -h, --help                       display usage information

Formatting options
Changing these have no effect unless also specifying "-t/--retransform", losing manual changes

    -c, --no-chapter                 disable "Chapter X" in chapter titles
    -o, --no-toc                     disable table of contents
    -s, --hr-style STYLE             style of <hr> section breaks: asterism (default), fleuron, or scrollwork
    -v, --volumes START1-END1,...    split story into multiple volumes
    -y, --hr-symbol SYMBOL           symbol number for scrollwork or fleuron
```

`fimfic2pdf` will create a directory with the story ID as name, download the EPUB version of the story to that directory, unpack it to HTML, parse the HTML, transform it to LaTeX, and run `xelatex` to generate a PDF.

If you change any formatting options and want to rerun transformation with the new options, use the `-t` flag.

If you want to change the rendering, edit the generated files and run `fimfic2pdf` again. It will notice that the files are already downloaded and just rerun `xelatex` to include your edits.

To redo the entire process, including downloading the EPUB file, delete the working directory and run `fimfic2pdf` again.
