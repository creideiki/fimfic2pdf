# frozen_string_literal: true

require 'fimfic2pdf/transformer'

module FiMFic2PDF
  module FiMFic
    # Transforms FiMFiction HTML documents to LaTeX
    module Transformer
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

      def download_image(url)
        # We need a supported file name extension, or \includegraphics{}
        # doesn't work. But it doesn't care if the data format matches
        # the extension, and we don't know the data format until we've
        # asked the server, which we want to avoid if possible. So just
        # call everything .png.

        # Also, FiMFiction runs all external references through a URL
        # proxy, making it very difficult to determine the actual file
        # name. Just use the hex MD5 of the URL and hope there are no
        # collisions.
        filename = 'img-' + Digest::MD5.hexdigest(url.split('/')[-1]) + '.png' # rubocop:disable Style/StringConcatenation
        path = @options.id + File::SEPARATOR + filename

        if File.exist? path
          @logger.debug "Image #{url} already downloaded"
        else
          @logger.info "Fetching image from #{url}"
          response = HTTParty.get(url,
                                  headers: {
                                    'User-Agent' => "FiMFic2PDF/#{FiMFic2PDF::VERSION}"
                                  })
          raise "Failed to download image #{url}: #{response.code} #{response.message}" unless response.code == 200

          @logger.debug "Saving image as: #{path}"
          File.binwrite(path, response.body)
        end

        filename
      end
    end
  end
end
