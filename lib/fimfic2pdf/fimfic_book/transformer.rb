# frozen_string_literal: true

require 'fimfic2pdf/transformer'
require 'fimfic2pdf/fimfic/transformer'
require 'fimfic2pdf/book/transformer'

module FiMFic2PDF
  module FiMFic2Book
    # Transforms FiMFiction HTML documents to LaTeX
    class Transformer < FiMFic2PDF::Transformer
      include FiMFic2PDF::FiMFic::Transformer
      include FiMFic2PDF::Book::Transformer
    end
  end
end
