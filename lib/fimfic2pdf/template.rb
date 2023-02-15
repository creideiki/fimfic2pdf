# frozen_string_literal: true

require 'fimfic2pdf/version'

module FimFic2PDF
  # The top-level book LaTeX template
  class Template
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

    def volume_title(volnum)
      s = "\n\n"
      s += "% Title of table of contents\n"
      s += '\renewcommand{\contentsname}{\hfill Volume '
      s += romanize volnum
      s += ' \hfill}'
      s + "\n\n"
    end

    def select_hr(style, symbol)
      s = "\n\\newcommand{\\hr}{"
      case style
      when :asterism
        s += '\\asterism'
      when :fleuron
        raise "Invalid symbol #{symbol}" if symbol > 193

        s += "\\fleuron{#{symbol}}"
      when :line
        s += '\vspace{3ex}\hrule\vspace{3ex}'
      when :scrollwork
        raise "Invalid symbol #{symbol}" if symbol > 193

        s += "\\scrollwork{#{symbol}}"
      end
      s + "}\n\n"
    end

    def chapter_style(style)
      case style
      when :no_chapter
        '\titleformat{\chapter}[block]{\centering\bfseries\Huge}{}{0ex}{}[]'
      else
        ''
      end
    end

    # rubocop:disable Layout/HeredocIndentation
    def select_underline(style)
      case style
      when :fancy
        <<'UNDERLINE'
\newcommand{\fancyuline}[1]{%
  \uline{\phantom{#1}}%
  \llap{\contour{white}{#1}}%
}
UNDERLINE
      when :simple
        <<'UNDERLINE'
\usepackage{soul}
\newcommand{\fancyuline}[1]{\ul{#1}}
UNDERLINE
      when :italic
        '\newcommand{\fancyuline}[1]{\textit{#1}}'
      when :regular
        '\newcommand{\fancyuline}[1]{#1}'
      end
    end

    def style
      <<'TEMPLATE'
% https://amyrhoda.wordpress.com/2012/05/25/latex-to-lulu-the-making-of-aosa-geometry-and-headers-and-footers/

\documentclass[10pt]{book}
\usepackage{extsizes}
\usepackage[includefoot]{geometry}
%\usepackage[utf8]{inputenc}

% Include pictures
\usepackage{graphicx}

% define page size and margins etc
\geometry{
  paperwidth=6in,
  paperheight=9in,
  vmargin=1.9cm, % top and bottom margins
  inner=1.9cm, % inside margin
  outer=2.29cm, % outside margin
  bindingoffset=0.89cm % gutter
}

\usepackage{fancyhdr} % to format headers/footers

\pagestyle{fancy}

%% fiddle with chaptermark so we can make it not all caps
\renewcommand{\chaptermark}[1]{\markboth{#1}{}}
\renewcommand{\sectionmark}[1]{\markright{#1}{}}

%% next get rid of existing header and footer and header rule
\fancyhead{}
\fancyfoot{}
\renewcommand{\headrulewidth}{0pt}

% now make the footer the way we want it:
% page number on right side of footer for odd pages
\rfoot[]{\small{\thepage}}
% \fancyhfoffset[EL]{0cm} % this looks like it doesn't do anything, but
%                        % it seems to remind it to line up headers with the
%                        % rest of the text

% page number and chapter name on left side of footer for even pages
\lfoot[\small{\thepage}]

% Interpret underscores literally, not as subscript
\usepackage{underscore}

% Section breaks, replacing <hr />. The command "\hr" will be defined
% later to use one of these alternatives.

\usepackage[object=vectorian]{pgfornament}

% Scrollwork lines
% https://tex.stackexchange.com/a/76555
% Choose a line style between 80 and 89 from pgfornament:
% https://ctan.org/pkg/pgfornament

\newcommand{\scrollwork}[1]{%
  \nointerlineskip \vspace{1\baselineskip}\hspace{\fill}
  {
    \resizebox{0.5\linewidth}{1ex}
    {{%
    {\begin{tikzpicture}
    \node  (C) at (0,0) {};
    \node (D) at (9,0) {};
    \path (C) to [ornament=#1] (D);
    \end{tikzpicture}}}}}%
    \hspace{\fill}
    \par\nointerlineskip \vspace{1\baselineskip}
  }

% Asterism
% https://tex.stackexchange.com/a/364110

\newcommand{\asterism}{%
  \vspace{2.5ex}\par\noindent%
  \parbox{\textwidth}{\centering{*}\\[-4pt]{*}\enspace{*}\vspace{2ex}}\par%
}

% Fleuron
% https://tex.stackexchange.com/a/160343
% Choose a symbol from pgfornament:
% https://ctan.org/pkg/pgfornament

\newcommand{\fleuron}[1]{%
  \par\bigskip\noindent\hfill\pgfornament[width=17pt,anchor=south]{#1}\hfill\null\par\bigskip
}

% Fonts
\usepackage{xltxtra}  % Enable OpenType fonts
\setmainfont{Linux Libertine}  % Hopefully a reasonable and widely available default serif font

% Table of contents
% No extra vertical space between chapters
% Allow horizontal space for three-digit chapter numbers
\usepackage{tocbasic}
\DeclareTOCStyleEntry[dynnumwidth=true,beforeskip=0pt]{tocline}{chapter}

\setcounter{tocdepth}{0} % sets what level of header is shown in the TOC
\setcounter{secnumdepth}{1} % sets what level of subsect. are numbered

\usepackage[center]{titlesec} % to format chapter title pages
\assignpagestyle{\chapter}{fancy} % use the same footer on title pages as on body pages

% Print author for each part in an anthology
\DeclareTOCStyleEntry[dynnumwidth=true,numwidth=0pt]{tocline}{part}
\usepackage{tocdata}

\usepackage{microtype}

% introduce penalty for widows and orphans (can increase to 10 000, although
% not recommended)
% upped the widow/orphan penalty to 600 from 300; seems to have removed
% all widows and orphans -- ARB Mar 30 2012
\widowpenalty=600
\clubpenalty=600

\raggedbottom

\emergencystretch 3em

\usepackage[normalem]{ulem}

% Underlines by https://alexwlchan.net/2017/10/latex-underlines/

% Default underline - handles descenders and embedded formatting, but
% not line breaks.

\usepackage{contour}

% Change \ULdepth only for \uline. \sout also uses \ULdepth, so we
% can't change it globally.
\usepackage{xpatch}
\xpatchcmd{\uline}
  {\bgroup}
  {\bgroup\def\ULdepth{1.8pt}}
  {}{}

\contourlength{1.0pt}

\usepackage{xcolor}

\usepackage{import}

% Optional vertical bars in the left margin for quotations
\usepackage[leftbars]{changebar}

TEMPLATE
    end

    def latex_escape_argument(string)
      string.
        gsub('#', '\#').
        gsub('%', '\%').
        gsub('&', '\\\&').
        gsub('$', '\\$').
        gsub(' ', '\ ').
        gsub(',', '{,}').
        gsub('=', '{=}')
    end

    def header(pdfinfo)
      s = <<TEMPLATE
% Clickable table of contents
\\usepackage[hidelinks,pdftitle=#{latex_escape_argument pdfinfo['title']},pdfauthor=#{latex_escape_argument pdfinfo['author']},addtopdfcreator=FiMFic2PDF\\ #{FimFic2PDF::VERSION}]{hyperref}
TEMPLATE

      s += <<'TEMPLATE'
\makeatletter
\@addtoreset{chapter}{part}
\makeatother

\begin{document}

\frontmatter

TEMPLATE
      s
    end

    def toc
      '\tableofcontents'
    end

    def body
      '\mainmatter'
    end

    def chapters(volume)
      "\\input{vol#{volume + 1}-chapters}"
    end

    def footer
      <<'TEMPLATE'

\backmatter

\end{document}
TEMPLATE
    end
    # rubocop:enable Layout/HeredocIndentation
  end
end
