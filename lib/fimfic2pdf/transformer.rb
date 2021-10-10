# frozen_string_literal: true

require 'logger'
require 'nokogiri'
require 'yaml'

module FimFic2PDF
  # Transforms HTML documents to LaTeX
  class Transformer
    attr_accessor :conf

    def initialize(story_id)
      @story_id = story_id
      @logger = Logger.new($stderr)
      @logger.debug "Preparing to transform story #{@story_id}"
      @dir = story_id.to_s
      @config_file = @dir + File::SEPARATOR + 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
    end

    def parse_metadata
      @logger.debug "Reading story metadata"
      unless @conf['story']['title'] and @conf['story']['author']
        @logger.debug "Not already parsed, reading from file #{@conf['story']['metadata']}"
        doc = File.open(@conf['story']['metadata']) { |f| Nokogiri::HTML(f) }
        @conf['story']['title'] = doc.at_xpath('/html/body/h1').text
        @conf['story']['author'] = doc.at_xpath('/html/body/p[1]/a[1]').text
      end
      @logger.debug "Title: #{@conf['story']['title']}"
      @logger.debug "Author: #{@conf['story']['author']}"

      @logger.debug "Reading chapter metadata"
      @conf['story']['chapters'].each do |chapter|
        unless chapter['title']
          @logger.debug "Not already parsed, reading from file #{chapter['html']}"
          doc = File.open(chapter['html']) { |f| Nokogiri::HTML(f) }
          chapter['title'] = doc.at_xpath('/html/head/title').text
          @logger.debug "Chapter read: #{chapter['title']}"
        end
      end
    end

    def visit(node, file)
      case node.type
      when Nokogiri::XML::Node::TEXT_NODE
        visit_text(node, file)
      when Nokogiri::XML::Node::ELEMENT_NODE
        if self.respond_to? "visit_#{node.name}"
          self.send("visit_#{node.name}", node, file)
        else
          raise "Unsupported HTML element #{node.name}"
        end
      else
        raise "Unsupported node type #{node.type}"
      end
    end

    def visit_text(node, file)
      if /^-+$/.match node.text
        file.write '\vspace{2ex}\hrule\vspace{2ex}'
      else
        file.write node.text
      end
    end

    def visit_p(node, file)
      file.write "\n"
      node.children.each.map { |c| visit(c, file) }
      file.write "\n"
    end

    def visit_span(node, file)
      opening = ''
      ending = ''
      node.attributes['style'].value.split(';').each do |style|
        case style
        when 'font-size:0.875em'
          opening += '\begin{small}'
          ending = '\end{small}' + ending
        when 'font-size:0.75em'
          opening += '\begin{footnotesize}'
          ending = '\end{footnotesize}' + ending
        when 'font-style:italic'
          opening += '\textit{'
          ending = '}' + ending
        when 'font-weight:bold'
          opening += '\textbf{'
          ending = '}' + ending
        else
          raise "Unsupported span style #{style}"
        end
      end
      file.write opening
      node.children.each.map { |c| visit(c, file) }
      file.write ending
    end

    def visit_i(node, file)
      file.write '\textit{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    def transform
      @logger.debug 'Transforming story'

      @conf['story']['chapters'].each do |chapter|
        @logger.debug "Transforming chapter: #{chapter['title']}"
        doc = File.open(chapter['html']) { |f| Nokogiri::HTML(f) }
        unless chapter['tex']
          chapter['tex'] = @dir + File::SEPARATOR +
                           File.basename(chapter['html'], '.html') + '.tex'
        end
        File.open(chapter['tex'], 'wb') do |tex|
          tex.write("\\chapter{#{chapter['title']}}\n\n")
          doc.xpath('/html/body/p').map { |p| visit_p(p, tex) }
        end
      end
    end

    def write_config
      @logger.debug 'Writing configuration from transformer'
      File.open(@dir + File::SEPARATOR + 'config.yaml', 'wb') do |f|
        f.write YAML.dump @conf
      end
    end
  end
end
