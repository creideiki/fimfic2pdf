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
      def style
        <<'TEMPLATE'
\documentclass{novel}

\SetHeadFootStyle{2}

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
      end

      def body() end

      def footer
        "\n\\end{document}\n"
      end
      # rubocop:enable Layout/HeredocIndentation
    end
  end
end
