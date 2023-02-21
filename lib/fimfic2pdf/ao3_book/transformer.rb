# frozen_string_literal: true

require 'fimfic2pdf/transformer'
require 'fimfic2pdf/ao3/transformer'
require 'fimfic2pdf/book/transformer'

module FiMFic2PDF
  module AO32Book
    # Transforms FiMFiction HTML documents to LaTeX
    class Transformer < FiMFic2PDF::Transformer
      include FiMFic2PDF::AO3::Transformer
      include FiMFic2PDF::Book::Transformer
    end
  end
end
