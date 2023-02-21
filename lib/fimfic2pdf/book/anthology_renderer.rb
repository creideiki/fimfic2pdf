# frozen_string_literal: true

require 'fimfic2pdf/anthology_renderer'

module FiMFic2PDF
  module Book
    # Calls LaTeX to render the story into PDF format.
    class AnthologyRenderer < FiMFic2PDF::AnthologyRenderer
      def tex_program
        'xelatex'
      end

      def num_passes
        4
      end
    end
  end
end
