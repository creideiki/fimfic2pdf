# frozen_string_literal: true

module FimFic2PDF
  # The top-level book LaTeX template
  class Template
    # rubocop:disable Layout/HeredocIndentation
    def style
      <<'TEMPLATE'
% https://amyrhoda.wordpress.com/2012/05/25/latex-to-lulu-the-making-of-aosa-geometry-and-headers-and-footers/

\documentclass{book}
\usepackage[includefoot]{geometry}
%\usepackage[utf8]{inputenc}

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

% Fonts
\usepackage{xltxtra}  % Enable OpenType fonts
\setmainfont{Linux Libertine}  % Hopefully a reasonable and widely available default serif font

% Table of contents
\usepackage{tocloft}  % to typeset table of contents
\usepackage{hyperref} % clickable links
\setlength{\cftbeforechapskip}{0em}  % No extra space between chapters
%\renewcommand{\cftchapdotsep}{\cftdotsep}  % Print dotted line between chapter title and page number

%\renewcommand{\cftchapfont}{\sffamily}     % set TOC entries to sserif
%\renewcommand{\cftchappagefont}{\sffamily} % set TOC page numbers to sserif

% format title of TOC: make sure this matches chapter head format as set below
%\renewcommand{\cfttoctitlefont}{\hfill\Huge\sffamily}

\setcounter{tocdepth}{0} % sets what level of header is shown in the TOC
\setcounter{secnumdepth}{1} % sets what level of subsect. are numbered

\usepackage[center]{titlesec} % to format chapter title pages
\assignpagestyle{\chapter}{fancy} % use the same footer on title pages as on body pages

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

\usepackage{xcolor}
TEMPLATE
    end

    def header
      <<'TEMPLATE'
\begin{document}

\frontmatter

\include{introduction}

\tableofcontents

\mainmatter

TEMPLATE
    end

    def chapters(volume)
      "\\include{vol#{volume + 1}-chapters}"
    end

    def footer
      <<'TEMPLATE'

\backmatter

\include{colophon}

\end{document}
TEMPLATE
    end
    # rubocop:enable Layout/HeredocIndentation
  end
end
