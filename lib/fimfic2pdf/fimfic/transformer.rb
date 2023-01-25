# frozen_string_literal: true

require 'fimfic2pdf/transformer'

module FimFic2PDF
  module FiMFic
    # Transforms FiMFiction HTML documents to LaTeX
    class Transformer < FimFic2PDF::Transformer
      def read_title_and_author
        return if @conf['story']['title'] and @conf['story']['author']

        @logger.debug "Not already parsed, reading from file #{@conf['story']['metadata']}"
        doc = Nokogiri::HTML(File.open(@conf['story']['metadata']))
        @conf['story']['title'] = doc.at_xpath('/html/body/h1').text
        @conf['story']['author'] = doc.at_xpath('/html/body/p[1]/a[1]').text
      end

      def read_chapters
        @conf['story']['chapters'].each do |chapter|
          next if chapter['title']

          @logger.debug "Not already parsed, reading from file #{chapter['html']}"
          doc = Nokogiri::HTML(File.open(chapter['html']))
          chapter['title'] = doc.at_xpath('/html/head/title').text
        end
      end

      def visit_body(node, file)
        child = node.children[0]
        if child.type != Nokogiri::XML::Node::TEXT_NODE or
           child.text != "\n\t\t"
          raise "Unknown body format: pre-title is #{child.inspect}"
        end

        child = node.children[1]
        if child.type != Nokogiri::XML::Node::ELEMENT_NODE or
           child.name != 'h1'
          raise "Unknown body format: title is #{child.inspect}"
        end

        child = node.children[2]
        if child.type != Nokogiri::XML::Node::TEXT_NODE or
           not /^[[:space:]]+$/.match(child.text)
          raise "Unknown body format: post-title is #{child.inspect}"
        end

        node.children[3..].map { |c| visit(c, file) }
      end
    end
  end
end
