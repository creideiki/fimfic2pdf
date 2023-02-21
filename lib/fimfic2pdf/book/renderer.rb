# frozen_string_literal: true

require 'fimfic2pdf/renderer'

module FiMFic2PDF
  module Book
    # Calls XeLaTeX to render the story into PDF format.
    class Renderer < FiMFic2PDF::Renderer
      def tex_program
        'xelatex'
      end

      def num_passes
        4
      end
    end
  end
end
