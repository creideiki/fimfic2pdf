# frozen_string_literal: true

require 'fimfic2pdf/anthology'

module FiMFic2PDF
  module Book
    # Writes LaTex boilerplate for an anthology
    class Anthology < FiMFic2PDF::Anthology
      def interstitial(title, author = nil)
        if author
          "\n\n\\partauthor[#{title}]{#{title}}[]{#{author}}{}[]"
        else
          "\n\n\\part{#{title}}"
        end
      end
    end
  end
end
