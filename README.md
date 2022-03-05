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

Find the story ID, which is the numbers in the URL after `https://www.fimfiction.net/story/`. Then, run `fimfic2pdf -i ID`. The PDF will be saved as `ID/book.pdf`.

The default format uses 6x9" paper and includes a table of contents.

## Advanced usage

```
Usage: fimfic2pdf -i ID [options]

Saves files in a working directory named ./<ID>/.

When run multiple times:
* By default, only re-renders the PDF, including any manual changes to the LaTeX code.
* To re-parse the HTML and re-transform to LaTeX, losing any manual changes, use the "-t" flag.
* To re-download the EPUB file and start over, remove the ./<ID>/ directory.

    -i, --id ID                      story ID
    -t, --retransform                force re-parsing of the HTML and transforming to LaTeX

    -V, --version                    display version information
    -h, --help                       display usage information
```

`fimfic2pdf` will create a directory with the story ID as name, download the EPUB version of the story to that directory, unpack it to HTML, parse the HTML, transform it to LaTeX, and run `xelatex` to generate a PDF.

If you want to change the rendering, edit the generated files and run `fimfic2pdf` again. It will notice that the files are already downloaded and just rerun `xelatex` to include your edits.

If you change the transformer and want to rerun it, use the `-t` flag.

To redo the entire process, including downloading the EPUB file, delete the working directory and run `fimfic2pdf` again.
