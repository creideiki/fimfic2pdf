# frozen_string_literal: true

module FiMFic2PDF
  # General utility functions accessible from any module.
  module Utility
    def self.make_filename(author, title)
      [author.strip, title.strip].join('-').
        encode(Encoding.find('ASCII'), :invalid => :replace, :undef => :replace, :replace => '').
        gsub(/[^a-zA-Z0-9\- ]/, '').
        gsub(/\s+/, ' ').
        strip.
        gsub(' ', '_').
        downcase
    end
  end
end
