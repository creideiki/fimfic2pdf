# frozen_string_literal: true

require 'fimfic2pdf/novel/driver'
require 'fimfic2pdf/novel/anthology'
require 'fimfic2pdf/novel/anthology_renderer'
require 'fimfic2pdf/ao3/downloader'
require 'fimfic2pdf/ao3_novel/transformer'
require 'fimfic2pdf/novel/template'
require 'fimfic2pdf/novel/renderer'
require 'fimfic2pdf/version'

module FiMFic2PDF
  module AO32Novel
    Driver = FiMFic2PDF::Novel::Driver
    Anthology = FiMFic2PDF::Novel::Anthology
    AnthologyRenderer = FiMFic2PDF::Novel::AnthologyRenderer
    Downloader = FiMFic2PDF::AO3::Downloader
    Template = FiMFic2PDF::Novel::Template
    Renderer = FiMFic2PDF::Novel::Renderer
  end
end
