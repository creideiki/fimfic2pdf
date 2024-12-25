# frozen_string_literal: true

require 'fimfic2pdf/version'

module FiMFic2PDF
  module Novel
    # The top-level book LaTeX template
    class Template < FiMFic2PDF::Template
      def select_hr(style, _symbol)
        s = "\n\\newcommand{\\hr}{"
        case style
        when :asterism
          s += '\\asterism'
        when :sceneline
          s += '\\sceneline'
        when :scenestars
          s += '\\scenestars'
        end
        s + "}\n\n"
      end

      def select_underline(_style)
        '\newcommand{\fancyuline}[1]{\emph{#1}}'
      end

      def chapter_style(_style)
        ''
      end

      def volume_title(_volnum, _first_chapter)
        ''
      end

      # rubocop:disable Layout/HeredocIndentation
      def common_style
        <<'TEMPLATE'
\renewcommand\nofiles{}

\documentclass{novel}

% Interpret underscores literally, not as subscript
\usepackage{underscore}

% Asterism
% https://tex.stackexchange.com/a/364110

\newcommand{\asterism}{%
  \vspace{2.5ex}\par\noindent%
  \parbox{\textwidth}{\centering{*}\\[-4pt]{*}\enspace{*}\vspace{2ex}}\par%
}

\usepackage{lua-ul}

\usepackage{xcolor}

\usepackage{import}

\setdefaultlanguage{english}

TEMPLATE
      end

      def style
        common_style + <<'TEMPLATE'
\SetHeadFootStyle{2}
TEMPLATE
      end

      def anthology_style
        common_style + <<'TEMPLATE'
\SetHeadFootStyle{6}
TEMPLATE
      end

      def latex_escape_argument(string)
        string.
          gsub('#', '\#').
          gsub('%', '\%').
          gsub('&', '\\\&').
          gsub('$', '\\$').
          gsub(/  +/, ' ').
          gsub('\'', '\straightquote{}').
          gsub('"', '\straightdblquote{}').
          gsub(',', '{,}').
          gsub('=', '{=}')
      end

      def header(pdfinfo)
        <<TEMPLATE
\\SetTitle{#{latex_escape_argument pdfinfo['title']}}
\\SetAuthor{#{latex_escape_argument pdfinfo['author']}}
\\SetApplication{FiMFic2PDF #{FiMFic2PDF::VERSION}}

\\begin{document}

TEMPLATE
      end

      def front_matter(story, volume)
        <<~TEMPLATE
          \\frontmatter % Sets page number to i.

          % Half-Title Page
          \\thispagestyle{empty}
          \\null
          \\vspace*{7\\nbs}
          \\begin{adjustwidth}{3em}{3em}
          \\begin{center}
          \\begin{parascale}[2.0]
          #{story['title']}
          \\end{parascale}
          \\end{center}
          \\end{adjustwidth}
          \\clearpage

          % List of books, or blank
          \\thispagestyle{empty}
          \\null
          \\vspace*{3\\nbs}
          \\begin{center}
          Other stories by #{story['author']}
          \\end{center}
          \\clearpage

          % Title Page.
          \\thispagestyle{empty}
          \\vspace*{7\\nbs}
          \\begin{center}
          \\begin{parascale}[2.0]
          #{story['title']}
          \\end{parascale}
          \\vspace{2\\nbs}
          \\begin{parascale}[1.5]
          Volume #{romanize(volume)}
          \\end{parascale}
          \\vspace{4\\nbs}
          \\begin{parascale}[2.0]
          #{story['author']}
          \\end{parascale}
          % \\vfill
          % Publisher\\par
          \\end{center}
          \\clearpage

          % Copyright Page.
          \\thispagestyle{empty}
          \\null
          \\vfill
          \\begin{adjustwidth}{1em}{1em}
          \\begin{center}
          \\begin{parascale}[0.75]
          This is a work of fiction. Names, characters, business,
          events and incidents are the products of the author’s
          imagination. Any resemblance to actual persons, living or
          dead, or actual events is purely coincidental.

          \\vspace{1\\nbs}

          This fan work uses characters and locations that are
          copyright and trademarks of BLANK. The author makes no
          claim on BLANK's copyright or trademarks.

          \\vspace{1\\nbs}

          \\textsc{#{story['title']}}

          \\vspace{1\\nbs}

          Copyright © #{story['year']} by #{story['author']}
          \\end{parascale}
          \\end{center}
          \\end{adjustwidth}
          \\clearpage

          % Dedication or Epigraph or TOC or Acknowledgements or Author's Note or Map.
          % Alternatively, repeat the Half-Title.
          \\thispagestyle{empty}
          \\vspace*{7\\nbs}
          \\begin{center}
          \\begin{parascale}[1.25]
          Dedication
          \\end{parascale}
          \\end{center}
          \\clearpage

          \\thispagestyle{empty}
          \\null % Necessary for blank page.
          % Alternatively, Epigraph if it does not detract from facing page.
          \\clearpage

          \\mainmatter % Sets page number to 1 for following material.
        TEMPLATE
      end

      def body() end

      def footer
        "\n\\end{document}\n"
      end
      # rubocop:enable Layout/HeredocIndentation
    end
  end
end
