# frozen_string_literal: true

require 'fimfic2pdf/version'

module FiMFic2PDF
  # The top-level book LaTeX template
  class Template
    def initialize
      @logger = Logger.new($stderr, progname: 'Template')
    end

    # Make a roman numeral from a decimal number.
    def romanize(number)
      reductions = {
        1000 => 'M',
        900  => 'CM',
        500  => 'D',
        400  => 'CD',
        100  => 'C',
        90   => 'XC',
        50   => 'L',
        40   => 'XL',
        10   => 'X',
        9    => 'IX',
        5    => 'V',
        4    => 'IV',
        1    => 'I'
      }

      result = String.new

      while number.positive?
        reductions.each do |n, subst|
          next unless number / n >= 1 # if number contains at least one of n

          result << subst  # push corresponding symbol to result
          number -= n
          break            # break from each and start it anew so that
                           # the largest numbers are checked first
                           # again.
        end
      end

      result
    end

    # Return the static contents to be placed in template.tex, which will be
    # included first in every volume's .tex file.
    # def style() end

    # Return LaTeX code defining the rendering of a \chapter according
    # to the user's choice. Will be inserted in the templace TeX file
    # after the main style.
    # def chapter_style(style) end

    # Return LaTeX code defining the \hr command according to the
    # user's choice. Will be inserted in the templace TeX file after
    # the main style.
    # def select_hr(style, symbol) end

    # Return LaTeX code defining the \fancyuline command according to the
    # user's choice. Will be inserted in the templace TeX file after
    # the main style.
    # def select_underline(style) end

    # Escape a string for use as the argument to a LaTeX command.
    def latex_escape_argument(string)
      string.
        gsub('#', '\#').
        gsub('%', '\%').
        gsub('&', '\\\&').
        gsub('$', '\\$').
        gsub(',', '{,}').
        gsub('=', '{=}')
    end

    # Return LaTeX code for setting the volume title and resetting the
    # chapter counter. Will be inserted before the header in a
    # multi-volume book.
    # def volume_title(volnum, first_chapter) end

    # Return the volume header, which is LaTeX code which will be
    # placed at the top of every volume's .tex file, after the style
    # file has been included. This should include \begin{document}.
    # def header(pdfinfo) end

    # Return LaTeX code for writing the front matter (title page,
    # copyright page, dedication, etc.). Will be inserted in each
    # volume, after the header.
    # def front_matter(story, volume) end

    # Return LaTeX code to insert the table of contents. May or may
    # not be called depending on options.
    # def toc() end

    # Return LaTeX code to insert any sections before the first
    # chapter, such as \mainmatter.
    # def body() end

    def chapters(volume)
      "\n\\input{vol#{volume + 1}-chapters}"
    end

    # Return LaTeX code inserted after the chapters have been
    # included. This should include any trailing sections, such as
    # \backmatter, and \end{document}.
    # def footer() end
  end
end
