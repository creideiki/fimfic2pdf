# frozen_string_literal: true

require 'fimfic2pdf/transformer'
require 'fimfic2pdf/fimfic/transformer'
require 'fimfic2pdf/novel/transformer'

module FiMFic2PDF
  module FiMFic2Novel
    # Transforms FiMFiction HTML documents to LaTeX
    class Transformer < FiMFic2PDF::Transformer
      include FiMFic2PDF::FiMFic::Transformer
      include FiMFic2PDF::Novel::Transformer
    end
  end
end
