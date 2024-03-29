# frozen_string_literal: true

require 'fimfic2pdf/transformer'

module FiMFic2PDF
  module AO3
    # Transforms AO3 XHTML documents to LaTeX
    module Transformer
      def read_title_and_author
        unless @conf['story']['title'] and @conf['story']['author'] # rubocop:disable Style/GuardClause
          @logger.debug "Not already parsed, reading from file #{@conf['story']['metadata']}"
          doc = Nokogiri::XML(File.open(@conf['story']['metadata']))
          doc.remove_namespaces!
          @conf['story']['title'] = doc.at_xpath('/package/metadata/title').text
          @conf['story']['author'] = doc.at_xpath('/package/metadata/creator').text
        end
      end

      def read_chapters() end

      def visit_body(node, file)
        userstuff = node.at_xpath('.//div[@class="userstuff2"]')
        @logger.error 'No user content in chapter' unless userstuff
        visit(userstuff, file) if userstuff
      end

      def download_image(url)
        # AO3 includes images in the epub file, so we already have the
        # file.
        url
      end
    end
  end
end
