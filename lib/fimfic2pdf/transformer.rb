# frozen_string_literal: true

require 'digest'
require 'logger'
require 'nokogiri'
require 'stringio'
require 'yaml'

require 'fimfic2pdf/template'

module FimFic2PDF
  # Transforms HTML documents to LaTeX
  class Transformer
    attr_accessor :conf

    def initialize(options) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @story_id = options[:id]
      @logger = Logger.new($stderr, progname: 'Transformer')
      @logger.debug "Preparing to transform story #{@story_id}"
      @dir = @story_id.to_s
      @config_file = @dir + File::SEPARATOR + 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
      @volumes =
        if options.key? :volumes
          options[:volumes].map do |chapters|
            first, last = chapters.split '-'
            { 'first' => first.to_i, 'last' => last.to_i }
          end
        else
          [{ 'first' => @conf['story']['chapters'][0]['number'],
             'last'  => @conf['story']['chapters'][-1]['number'] }]
        end
      @volumes.each_with_index do |v, n|
        v['number'] = n + 1
        v['filename'] = @dir + File::SEPARATOR + # rubocop:disable Style/StringConcatenation
                        'vol' + (n + 1).to_s + '.tex'
      end
      @logger.info "Splitting into #{@volumes.size} volumes:"
      @volumes.each_with_index { |v, n| @logger.info "Volume #{n + 1}: Chapters #{v['first']} - #{v['last']}" }
      @conf['story']['volumes'] = @volumes
      @hr_style = options[:hr_style]
      @hr_symbol = options[:hr_symbol]
      @logger.debug "Using section break style #{@hr_style} with symbol #{@hr_symbol}"
      @replacements = {}
      @in_blockquote = false
      @chapter_style = options[:chapter_style]
      @logger.debug("Using chapter style #{@chapter_style || 'default'}")
      @chapters_with_underline = []
    end

    def validate_volumes
      chapter_usage = Array.new(@conf['story']['chapters'].size, 0)
      @volumes.each do |vol|
        vol['first'].upto(vol['last']) do |chapter|
          chapter_usage[chapter - 1] += 1
        end
      end
      do_abort = false
      chapter_usage.each_with_index do |usage, num|
        if usage.zero?
          @logger.error "Chapter #{num + 1} is not assigned to any volume"
          do_abort = true
        elsif usage > 1
          @logger.error "Chapter #{num + 1} is assigned to more than one volume"
          do_abort = true
        end
      end
      exit 1 if do_abort
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
        @logger.debug "Chapter read: #{chapter['number']} - #{chapter['title']}"
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
         not (/^[[:space:]]+$/).match(child.text)
        raise "Unknown body format: post-title is #{child.inspect}"
      end

      node.children[3..].map { |c| visit(c, file) }
    end

    def latex_escape(string)
      string.
        gsub(/#/, '\#').
        gsub('“', '``').
        gsub('”', "''").
        gsub('‘', '`').
        gsub('’', "'").
        gsub('…', '...').
        gsub('%', '\%').
        gsub('&', '\\\&').
        gsub('$', '\\$')
    end

    def visit_text(node, file)
      if /^-+$/.match node.text
        file.write '\vspace{2ex}\hrule\vspace{2ex}'
      else
        file.write latex_escape(node.text)
      end
    end

    def visit_p(node, file)
      file.write "\n"
      node.children.each.map { |c| visit(c, file) }
      file.write "\n"
    end

    # rubocop:disable Style/StringConcatenation, Metrics/BlockLength
    def visit_span(node, file)
      opening = ''
      ending = ''
      node.attributes['style']&.value&.split(';')&.each do |style|
        case style
        when 'font-size:2em'
          opening += '\begin{LARGE}'
          ending = '\end{LARGE}' + ending
        when 'font-size:1.5em'
          opening += '\begin{Large}'
          ending = '\end{Large}' + ending
        when 'font-size:0.875em', 'font-size:0.8125em'
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
          opening += '\fancyuline{'
          @chapter_has_underline = true
          ending = '}' + ending
        when 'text-decoration:line-through'
          opening += '\sout{'
          ending = '}' + ending
        when 'text-decoration:underline line-through'
          if @in_blockquote
            opening += '\sout{'
            ending = '}' + ending
          else
            opening += '\fancyuline{\sout{'
            @chapter_has_underline = true
            ending = '}}' + ending
          end
        when /^color:#([[:xdigit:]]+)$/
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
    # rubocop:enable Style/StringConcatenation, Metrics/BlockLength

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
      file.write '\fancyuline{' unless @in_blockquote
      @chapter_has_underline = true unless @in_blockquote
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
      file.write "\n", '\hr', "\n"
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

    def visit_img(node, file) # rubocop:disable Metrics/AbcSize
      url = node.attributes['src'].value

      # We need a supported file name extension, or \includegraphics{}
      # doesn't work. But it doesn't care if the data format matches
      # the extension, and we don't know the data format until we've
      # asked the server, which we want to avoid if possible. So just
      # call everything .png.

      # Also, FimFiction runs all external references through a URL
      # proxy, making it very difficult to determine the actual file
      # name. Just use the hex MD5 of the URL and hope there are no
      # collisions.
      name = 'img_' + Digest::MD5.hexdigest(url.split('/')[-1]) + '.png' # rubocop:disable Style/StringConcatenation
      path = @dir + File::SEPARATOR + name

      if File.exist? path
        @logger.debug "Image #{url} already downloaded"
      else
        @logger.info "Fetching image from #{url}"
        response = HTTParty.get(url,
                                headers: {
                                  'User-Agent' => "FimFic2PDF/#{FimFic2PDF::VERSION}"
                                })
        raise "Failed to download image #{url}: #{response.code} #{response.message}" unless response.code == 200

        @logger.debug "Saving image as: #{path}"
        File.binwrite(path, response.body)
      end

      file.write "\n\\includegraphics[width=\\textwidth]{#{name}}\n"
    end

    def visit_sub(node, file)
      file.write '\textsubscript{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    def visit_s(node, file)
      file.write '\sout{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    def visit_ul(node, file)
      file.write "\n", '\begin{itemize}'
      node.children.each.map { |c| visit(c, file) }
      file.write '\end{itemize}', "\n"
    end

    def visit_ol(node, file)
      file.write "\n", '\begin{enumerate}'
      node.children.each.map { |c| visit(c, file) }
      file.write '\end{enumerate}', "\n"
    end

    def visit_li(node, file)
      file.write "\n", '\item '
      node.children.each.map { |c| visit(c, file) }
    end

    def transform_volume(num)
      volume = @volumes[num]
      @logger.debug "Transforming volume #{num + 1}, chapters #{volume['first']} - #{volume['last']}"

      vol_str = 'vol' + (num + 1).to_s + '-' # rubocop:disable Style/StringConcatenation

      File.open(@dir + File::SEPARATOR + vol_str + 'chapters.tex', 'wb') do |chapters|
        @conf['story']['volumes'][num]['first'].upto(@conf['story']['volumes'][num]['last']) do |chapter_num|
          @chapter_has_underline = false
          chapter = @conf['story']['chapters'][chapter_num - 1]
          @logger.debug "Transforming chapter: #{chapter['number']} - #{chapter['title']}"
          doc = File.open(chapter['html']) { |f| Nokogiri::HTML(f) }
          chapter['tex'] ||= @dir + File::SEPARATOR +
                             File.basename(chapter['html'], '.html') + '.tex'
          File.open(chapter['tex'], 'wb') do |tex|
            tex.write("\\chapter{#{latex_escape(chapter['title'])}}\n\n")
            build = StringIO.new
            visit_body(doc.xpath('/html/body'), build)
            @replacements.each do |src, dst|
              build.string.gsub!(src, dst)
            end
            tex.write build.string
          end
          chapters.write "\\input{#{File.basename(chapter['tex'], '.tex')}}\n"
          if @chapter_has_underline
            @logger.info "Chapter has underline: #{chapter['number']} - #{chapter['title']}"
            @chapters_with_underline.append "#{chapter['number']} - #{chapter['title']}"
          end
        end
      end
    end

    def transform
      @logger.debug 'Transforming story'

      @volumes.each_index { |num| transform_volume num }

      @chapters_with_underline
    end

    def write_volume(num)
      @logger.debug "Writing LaTeX file for volume #{num + 1}"

      tmpl = FimFic2PDF::Template.new
      File.open(@volumes[num]['filename'], 'wb') do |f|
        f.write tmpl.style
        f.write tmpl.chapter_style(@chapter_style)
        f.write tmpl.select_hr(@hr_style, @hr_symbol)
        f.write tmpl.volume_title(num + 1)
        f.write tmpl.header
        f.write "\n\\setcounter{chapter}{#{@conf['story']['volumes'][num]['first'].to_i - 1}}\n"
        f.write tmpl.chapters(num)
        f.write tmpl.footer
      end
    end

    def write_story
      @logger.debug 'Writing top-level LaTeX files'

      @volumes.each_index { |num| write_volume num }
    end

    def write_config
      @logger.debug 'Writing configuration from transformer'
      File.binwrite(@dir + File::SEPARATOR + 'config.yaml', YAML.dump(@conf))
    end
  end
end
