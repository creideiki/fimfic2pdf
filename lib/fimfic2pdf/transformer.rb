# frozen_string_literal: true

require 'logger'
require 'nokogiri'
require 'stringio'
require 'yaml'

require 'fimfic2pdf/template'

module FimFic2PDF
  # Transforms HTML documents to LaTeX
  class Transformer
    attr_accessor :conf

    def initialize(story_id)
      @story_id = story_id
      @logger = Logger.new($stderr, progname: 'Transformer')
      @logger.debug "Preparing to transform story #{@story_id}"
      @dir = story_id.to_s
      @config_file = @dir + File::SEPARATOR + 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
      @replacements = {}
      @in_blockquote = false
    end

    def parse_metadata
      @logger.debug 'Reading story metadata'
      unless @conf['story']['title'] and @conf['story']['author']
        @logger.debug "Not already parsed, reading from file #{@conf['story']['metadata']}"
        doc = File.open(@conf['story']['metadata']) { |f| Nokogiri::HTML(f) }
        @conf['story']['title'] = doc.at_xpath('/html/body/h1').text
        @conf['story']['author'] = doc.at_xpath('/html/body/p[1]/a[1]').text
      end
      @logger.debug "Title: #{@conf['story']['title']}"
      @logger.debug "Author: #{@conf['story']['author']}"

      @logger.debug 'Reading chapter metadata'
      @conf['story']['chapters'].each do |chapter|
        next if chapter['title']

        @logger.debug "Not already parsed, reading from file #{chapter['html']}"
        doc = File.open(chapter['html']) { |f| Nokogiri::HTML(f) }
        chapter['title'] = doc.at_xpath('/html/head/title').text
        @logger.debug "Chapter read: #{chapter['title']}"
      end
    end

    def visit(node, file)
      case node.type
      when Nokogiri::XML::Node::TEXT_NODE
        visit_text(node, file)
      when Nokogiri::XML::Node::ELEMENT_NODE
        raise "Unsupported HTML element #{node.name}" unless
          respond_to? "visit_#{node.name}"

        send("visit_#{node.name}", node, file)
      else
        raise "Unsupported node type #{node.type}"
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
         child.text != "\n\n\n"
        raise "Unknown body format: post-title is #{child.inspect}"
      end

      node.children[3..].map { |c| visit(c, file) }
    end

    def visit_text(node, file)
      if /^-+$/.match node.text
        file.write '\vspace{2ex}\hrule\vspace{2ex}'
      else
        file.write(
          node.text.
            gsub(/#/, '\#').
            gsub('“', '``').
            gsub('”', "''").
            gsub('‘', '`').
            gsub('’', "'").
            gsub('…', '...').
            gsub('%', '\%').
            gsub('&', '\\\&')
        )
      end
    end

    def visit_p(node, file)
      file.write "\n"
      node.children.each.map { |c| visit(c, file) }
      file.write "\n"
    end

    # rubocop:disable Style/StringConcatenation
    def visit_span(node, file)
      opening = ''
      ending = ''
      node.attributes['style'].value.split(';').each do |style|
        case style
        when 'font-size:2em'
          opening += '\begin{LARGE}'
          ending = '\end{LARGE}' + ending
        when 'font-size:1.5em'
          opening += '\begin{Large}'
          ending = '\end{Large}' + ending
        when 'font-size:0.875em'
          opening += '\begin{small}'
          ending = '\end{small}' + ending
        when 'font-size:0.75em'
          opening += '\begin{footnotesize}'
          ending = '\end{footnotesize}' + ending
        when 'font-size:0.5em'
          opening += '\begin{scriptsize}'
          ending = '\end{scriptsize}' + ending
        when 'font-style:italic'
          opening += '\textit{'
          ending = '}' + ending
        when 'font-weight:bold'
          opening += '\textbf{'
          ending = '}' + ending
        when 'text-decoration:underline'
          opening += '\underline{'
          ending = '}' + ending
        when 'text-decoration:line-through'
          opening += '\sout{'
          ending = '}' + ending
        when 'text-decoration:underline line-through'
          if @in_blockquote
            opening += '\sout{'
            ending = '}' + ending
          else
            opening += '\underline{\sout{'
            ending = '}}' + ending
          end
        when /^color:#([[:digit:]]+)$/
          colour = Regexp.last_match(1)
          case colour.size
          when 6
            # Already in the correct format
          when 3
            colour = colour.chars.map { |c| c * 2 }.join
          else
            raise "Unsupported colour format: #{colour}"
          end
          opening += '\textcolor[HTML]{' + colour + '}{'
          ending += '}'
        when 'font-variant-caps:small-caps'
          opening += '\textsc{'
          ending = '}' + ending
        else
          raise "Unsupported span style #{style}"
        end
      end
      file.write opening
      node.children.each.map { |c| visit(c, file) }
      file.write ending
    end
    # rubocop:enable Style/StringConcatenation

    def visit_i(node, file)
      file.write '\textit{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    def visit_b(node, file)
      file.write '\textbf{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    def visit_br(_node, file)
      file.write "\n\n"
    end

    def visit_u(node, file)
      file.write '\underline{' unless @in_blockquote
      node.children.each.map { |c| visit(c, file) }
      file.write '}' unless @in_blockquote
    end

    def write_footnote(node, file)
      footnote = StringIO.new
      footnote.write '\footnote{'
      node.children.each.map { |c| visit(c, footnote) }
      footnote.write '}'

      marker = /\*[[:space:]]*/.match footnote.string
      if not marker
        file.write footnote.string
        return
      end

      # There was a footnote marker. Look at the previous node, find
      # the footnote marker there, and remove it.

      previous = StringIO.new
      visit(node.previous, previous)

      if previous.string.include? marker[0]
        referent = previous.string.gsub(marker[0], footnote.string.gsub(marker[0], ''))
        @replacements[previous.string] = referent
      else
        file.write footnote.string.gsub(marker[0], '')
      end
    end

    def visit_figure(node, file)
      case node.attributes['class'].value
      when 'bbcode-figure-right'
        write_footnote(node, file)
      else
        raise "Unsupported figure class #{node.attributes['class'].value}"
      end
    end

    def visit_a(node, file)
      node.children.each.map { |c| visit(c, file) }
    end

    def visit_sup(node, file)
      file.write '\textsuperscript{\small '
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    def visit_hr(_node, file)
      file.write "\n", '\par\noindent\rule{\textwidth}{0.5pt}', "\n"
    end

    def visit_blockquote(node, file)
      previous_blockquote = @in_blockquote
      @in_blockquote = true
      file.write "\n", '\begin{quotation}', "\n"
      node.children.each.map { |c| visit(c, file) }
      file.write "\n", '\end{quotation}', "\n"
      @in_blockquote = previous_blockquote
    end

    # rubocop:disable Style/StringConcatenation
    def visit_div(node, file)
      opening = ''
      ending = ''
      node.attributes['style'].value.split(';').each do |style|
        case style
        when 'text-align:center'
          opening += '\begin{center}'
          ending = '\end{center}' + ending
        else
          raise "Unsupported div style #{style}"
        end
      end
      file.write opening
      node.children.each.map { |c| visit(c, file) }
      file.write ending
    end
    # rubocop:enable Style/StringConcatenation

    def visit_h1(node, file)
      file.write "\n", '\begin{LARGE}'
      node.children.each.map { |c| visit(c, file) }
      file.write '\end{LARGE}', "\n"
    end

    def visit_h2(node, file)
      file.write "\n", '\begin{Large}'
      node.children.each.map { |c| visit(c, file) }
      file.write '\end{Large}', "\n"
    end

    def transform
      @logger.debug 'Transforming story'

      File.open(@dir + File::SEPARATOR + 'chapters.tex', 'wb') do |chapters|
        @conf['story']['chapters'].each do |chapter|
          @logger.debug "Transforming chapter: #{chapter['title']}"
          doc = File.open(chapter['html']) { |f| Nokogiri::HTML(f) }
          chapter['tex'] ||= @dir + File::SEPARATOR +
                             File.basename(chapter['html'], '.html') + '.tex'
          File.open(chapter['tex'], 'wb') do |tex|
            tex.write("\\chapter{#{chapter['title']}}\n\n")
            build = StringIO.new
            visit_body(doc.xpath('/html/body'), build)
            @replacements.each do |src, dst|
              build.string.gsub!(src, dst)
            end
            tex.write build.string
          end
          chapters.write "\\input{#{File.basename(chapter['tex'], '.tex')}}\n"
        end
      end
    end

    def write_book
      @logger.debug 'Writing top-level LaTeX file'
      tmpl = FimFic2PDF::Template.new
      File.open(@dir + File::SEPARATOR + 'book.tex', 'wb') do |f|
        f.write tmpl.to_s
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
