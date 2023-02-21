# frozen_string_literal: true

require 'fimfic2pdf/book/driver'
require 'fimfic2pdf/book/anthology'
require 'fimfic2pdf/book/anthology_renderer'
require 'fimfic2pdf/fimfic/downloader'
require 'fimfic2pdf/fimfic_book/transformer'
require 'fimfic2pdf/book/template'
require 'fimfic2pdf/book/renderer'
require 'fimfic2pdf/version'

module FiMFic2PDF
  module FiMFic2Book
    Driver = FiMFic2PDF::Book::Driver
    Anthology = FiMFic2PDF::Book::Anthology
    AnthologyRenderer = FiMFic2PDF::Book::AnthologyRenderer
    Downloader = FiMFic2PDF::FiMFic::Downloader
    Template = FiMFic2PDF::Book::Template
    Renderer = FiMFic2PDF::Book::Renderer
  end
end
