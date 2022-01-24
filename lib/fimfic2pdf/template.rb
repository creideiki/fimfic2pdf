# frozen_string_literal: true

module FimFic2PDF
  # The top-level book LaTeX template
  class Template
    # rubocop:disable Layout/HeredocIndentation
    def to_s
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

\usepackage[T1]{fontenc}
\usepackage{tgtermes}    % body font
\usepackage{tgheros}     % sans-serif font

%\usepackage{tocloft}  % to typeset table of contents

%\renewcommand{\cftchapfont}{\sffamily}     % set TOC entries to sserif
%\renewcommand{\cftchappagefont}{\sffamily} % set TOC page numbers to sserif

% format title of TOC: make sure this matches chapter head format as set below
%\renewcommand{\cfttoctitlefont}{\hfill\Huge\sffamily}

\setcounter{tocdepth}{0} % sets what level of header is shown in the TOC
\setcounter{secnumdepth}{1} % sets what level of subsect. are numbered

%\usepackage[titlesec]{lwarp} % to format chapter title pages

% format chapter title pages
%\titleformat{\chapter}
%  [display] % shape/type of title
%  {\sffamily}
%  {\large \thechapter }
%  [\thispagestyle{plain} % suppress page numbers
%]% end of what comes after title

\usepackage{microtype}

% introduce penalty for widows and orphans (can increase to 10 000, although
% not recommended)
% upped the widow/orphan penalty to 600 from 300; seems to have removed
% all widows and orphans -- ARB Mar 30 2012
\widowpenalty=600
\clubpenalty=600

\raggedbottom

\emergencystretch 3em

\begin{document}

\frontmatter

\include{introduction}

\tableofcontents

\mainmatter

\include{chapters}

\backmatter

\include{colophon}

\end{document}
TEMPLATE
      # rubocop:enable Layout/HeredocIndentation
    end
  end
end
