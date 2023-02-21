# frozen_string_literal: true

require 'fimfic2pdf/novel/driver'
require 'fimfic2pdf/anthology'
require 'fimfic2pdf/novel/anthology_renderer'
require 'fimfic2pdf/fimfic/downloader'
require 'fimfic2pdf/fimfic_novel/transformer'
require 'fimfic2pdf/novel/template'
require 'fimfic2pdf/novel/renderer'
require 'fimfic2pdf/version'

module FiMFic2PDF
  module FiMFic2Novel
    Driver = FiMFic2PDF::Novel::Driver
    Anthology = FiMFic2PDF::Anthology
    AnthologyRenderer = FiMFic2PDF::Novel::AnthologyRenderer
    Downloader = FiMFic2PDF::FiMFic::Downloader
    Template = FiMFic2PDF::Novel::Template
    Renderer = FiMFic2PDF::Novel::Renderer
  end
end
