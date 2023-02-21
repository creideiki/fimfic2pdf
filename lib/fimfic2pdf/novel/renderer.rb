# frozen_string_literal: true

require 'fimfic2pdf/renderer'

module FiMFic2PDF
  module Novel
    # Calls LuaLaTeX to render the story into PDF format.
    class Renderer < FiMFic2PDF::Renderer
      def tex_program
        'lualatex'
      end

      def num_passes
        2
      end
    end
  end
end
