# FimFic2PDF

Renders stories from [FimFiction](https://www.fimfiction.net/) as PDF.

## Requirements

* Ruby 3
  * httparty
  * nokogiri
  * rubyzip
* xelatex

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
Usage: fimfic2pdf [options]

    -i, --id ID                      story ID
    -f, --[no-]skip-fetch            skip fetch (download) step
    -u, --[no-]skip-unpack           skip unpack step
    -g                               skip write download configuration step
        --[no-]skip-write-download-config
    -p, --[no-]skip-parse-metadata   skip parse metadata step
    -t, --[no-]skip-transform        skip transform (generate LaTeX) step
    -b, --[no-]skip-write-book       skip write book (top-level LaTeX file) step
    -w, --[no-]skip-write-config     skip write transform config step
    -r, --[no-]skip-render           skip render PDF step

    -V, --version                    display version information
    -h, --help                       display usage information
```

`fimfic2pdf` will create a directory with the story ID as name, download the EPUB version of the story to that directory, unpack it to HTML, parse the HTML, transform it to LaTeX, and run `xelatex` to generate a PDF.

If you want to change the rendering, simply edit the files and run `fimfic2pdf` again, skipping the steps whose output you changed. For example, if you changed `book.tex` to yield a different layout, you would run `fimfic2pdf -i <ID> -f -u -g -p -t -b -w` to skip all steps but rendering.
