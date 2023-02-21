# frozen_string_literal: true

require 'fimfic2pdf/anthology'

module FiMFic2PDF
  module Novel
    # Writes LaTex boilerplate for an anthology
    class Anthology < FiMFic2PDF::Anthology
      def interstitial(title, author = nil)
        s = <<~TEMPLATE

          \\cleartorecto
          \\thispagestyle{empty}
          \\SetVersoHeadText{#{author}}
          \\SetRectoHeadText{#{title}}
          \\vspace*{10\\nbs}
          \\begin{adjustwidth}{5em}{5em}
          \\begin{parascale}[2.0]
          \\center{#{title}}
          \\end{parascale}
        TEMPLATE
        if author
          s += <<~TEMPLATE
            \\vspace*{4\\nbs}
            \\begin{parascale}[1.5]
            \\center{#{author}}
            \\end{parascale}
          TEMPLATE
        end
        s += <<~TEMPLATE
          \\end{adjustwidth}
          \\clearpage
        TEMPLATE
        s
      end
    end
  end
end
