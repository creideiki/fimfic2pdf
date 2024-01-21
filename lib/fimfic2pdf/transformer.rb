# frozen_string_literal: true

require 'logger'
require 'nokogiri'
require 'stringio'
require 'yaml'

module FiMFic2PDF
  # Transforms HTML documents to LaTeX
  class Transformer
    attr_reader :conf
    attr_accessor :chapter_has_underline,
                  :outside_double_quotes, :outside_single_quotes

    def make_filename(author, title)
      [author.strip, title.strip].join('-').
        encode(Encoding.find('ASCII'), :invalid => :replace, :undef => :replace, :replace => '').
        gsub(/[^a-zA-Z0-9\- ]/, '').
        gsub(/\s+/, ' ').
        strip.
        gsub(' ', '_').
        downcase
    end

    def initialize(options)
      @options = options
      @logger = Logger.new($stderr, progname: 'Transformer')
      @logger.debug "Preparing to transform story #{@options.id}"
      @config_file = @options.id + File::SEPARATOR + 'config.yaml'
      @conf = YAML.safe_load_file(@config_file)
      @logger.debug "Using section break style #{@options.hr_style}" +
                    if @options.hr_symbol
                      " with symbol #{@options.hr_symbol}"
                    else
                      ''
                    end
      @replacements = {}
      @in_blockquote = false
      @logger.debug("Using chapter style #{@options.chapter_style || 'default'}")
      @warnings = {
        underline: {
          chapters: [],
          message: 'Underlines present in the following chapters. Please check line breaks manually.'
        },
        unbalanced_quotes: {
          chapters: [],
          message: 'Unbalanced quotes present in the following chapters. ' \
                   'Please check quotation manually, fix balancing in the HTML files, ' \
                   'and re-run with "--retransform --prettify-quotes"'
        },
        unbalanced_single_quotes: {
          chapters: [],
          message: 'Unbalanced single quotes present in the following chapters. ' \
                   'Please check quotation manually, fix balancing in the HTML files, ' \
                   'and re-run with "--retransform --prettify-single-quotes"'
        }
      }
    end

    def prepare_volumes # rubocop:disable Metrics/AbcSize
      @volumes =
        if @options.volumes
          @options.volumes.map do |chapters|
            first, last = chapters.split '-'
            { 'first' => first.to_i, 'last' => last.to_i }
          end
        else
          [{ 'first' => @conf['story']['chapters'][0]['number'],
             'last'  => @conf['story']['chapters'][-1]['number'] }]
        end
      @volumes.each_with_index do |v, n|
        v['number'] = n + 1
        file_base = @options.id + File::SEPARATOR +
                    make_filename(@conf['story']['author'], @conf['story']['title']) +
                    '-' + (n + 1).to_s
        v['tex_file'] = file_base + '.tex'
        v['aux_file'] = file_base + '.aux'
        v['pdf_file'] = file_base + '.pdf'
      end
      @logger.info "Splitting into #{@volumes.size} volumes:"
      @volumes.each_with_index { |v, n| @logger.info "Volume #{n + 1}: Chapters #{v['first']} - #{v['last']}" }
      @conf['story']['volumes'] = @volumes
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

    # Read story title and author from metadata files, storing the
    # result in @conf['story']['title'] and @conf['story']['author'].
    # def read_title_and_author() end

    # Read chapter titles from HTML files, storing the result in
    # @conf['story']['chapters'].
    # def read_chapters() end

    def parse_metadata
      @logger.debug 'Reading story metadata'

      read_title_and_author

      @logger.debug "Title: #{@conf['story']['title']}"
      @logger.debug "Author: #{@conf['story']['author']}"

      @logger.debug 'Reading chapter metadata'

      read_chapters

      @conf['story']['chapters'].each do |chapter|
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

    # Top-level interface to the HTML transformer. Skip any preamble
    # (e.g. titles) and call visit() on the remaining nodes.
    # def visit_body(node, file) end

    def latex_escape(string)
      string.
        gsub('\\', '\\textbackslash{}').
        gsub('#', '\#').
        gsub('%', '\%').
        gsub('&', '\\\&').
        gsub('$', '\\$')
    end

    def unicodify(string)
      string.
        gsub('...', '…')
    end

    def prettify_double_quotes(text)
      text.chars.map do |char|
        case char
        when '“'
          @outside_double_quotes = false
          '“'
        when '”'
          @outside_double_quotes = true
          '”'
        when '"'
          @outside_double_quotes = !@outside_double_quotes
          @outside_double_quotes ? '”' : '“'
        else
          char
        end
      end.join
    end

    def prettify_single_quotes(text)
      new_text = ''
      text.chars.each_with_index do |char, index|
        case char
        when '‘'
          @outside_single_quotes = false
          new_text += '‘'
        when '’'
          @outside_single_quotes = true
          new_text += '’'
        when '\''
          # Is this a single quote or an apostrophe?
          if index.zero?
            # Starts a text node - assume left single quote
            new_text += '‘'
            @outside_single_quotes = false
          elsif index == text.size - 1
            # Ends a text node - assume right single quote
            new_text += '’'
            @outside_single_quotes = true
          elsif text[index - 1] =~ /\p{Word}/ and
                text[index + 1] =~ /\p{Word}/
            # Between two letters - assume apostrophe
            new_text += char
          else
            # None of the above - assume single quote, alternate
            # directions
            @outside_single_quotes = !@outside_single_quotes
            new_text += (@outside_single_quotes ? '’' : '‘')
          end
        else
          new_text += char
        end
      end
      new_text
    end

    def visit_text(node, file)
      text = unicodify node.text
      text.gsub! "\n", ' '
      if /^ *-{4,} *$/.match text
        visit_hr(node, file)
      else
        text = latex_escape text
        text = prettify_double_quotes(text) if @options.prettify_quotes
        text = prettify_single_quotes(text) if @options.prettify_single_quotes
        file.write text
      end
    end

    def visit_p(node, file)
      return if node.children.size == 1 and
                node.children[0].type == Nokogiri::XML::Node::TEXT_NODE and
                /^[[:blank:]]*$/.match(node.children[0].text)

      file.write "\n"
      node.children.each.map { |c| visit(c, file) }
      file.write "\n"
    end

    # rubocop:disable Style/StringConcatenation, Lint/DuplicateBranch
    def span_open(style)
      case style
      when 'font-style:italic'
        '\textit{'
      when 'font-weight:bold'
        '\textbf{'
      when 'text-decoration:underline'
        @chapter_has_underline = true
        '\fancyuline{'
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
        '\textcolor[HTML]{' + colour + '}{'
      when 'font-variant-caps:small-caps'
        '\textsc{'
      else # rubocop:disable Style/EmptyElse
        nil
      end
    end

    def span_close(style)
      case style
      when 'font-style:italic'
        '}'
      when 'font-weight:bold'
        '}'
      when 'text-decoration:underline'
        '}'
      when /^color:#([[:xdigit:]]+)$/
        '}'
      when 'font-variant-caps:small-caps'
        '}'
      else # rubocop:disable Style/EmptyElse
        nil
      end
    end
    # rubocop:enable Style/StringConcatenation, Lint/DuplicateBranch

    def visit_span(node, file)
      opening = ''
      closing = ''
      node.attributes['style']&.value&.split(';')&.sort&.each do |style|
        this_open = span_open style
        this_close = span_close style

        raise "Unsupported span style #{style}" unless this_open and this_close

        opening += this_open
        closing = this_close + closing
      end
      file.write opening
      node.children.each.map { |c| visit(c, file) }
      file.write closing
    end

    def visit_i(node, file)
      file.write '\textit{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    alias visit_em visit_i

    def visit_b(node, file)
      file.write '\textbf{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    alias visit_strong visit_b

    def visit_br(_node, file)
      file.write "\n\n"
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
      case node.attributes['class']&.value
      when 'afterward'
        visit_authors_notes(node, file)
      else
        visit_plain_blockquote(node, file)
      end
    end

    def visit_authors_notes(node, file)
      case @options.authors_notes
      when :remove
        return # rubocop:disable Style/RedundantReturn
      when :plain
        visit_plain_blockquote(node, file)
      end
    end

    # rubocop:disable Style/StringConcatenation
    def visit_div(node, file)
      opening = ''
      ending = ''
      if node.attributes.include? 'style'
        node.attributes['style'].value.split(';').each do |style|
          case style
          when 'text-align:center'
            opening += '\begin{center}'
            ending = '\end{center}' + ending
          when 'text-align:right'
            opening += '\begin{flushright}'
            ending = '\end{flushright}' + ending
          else
            raise "Unsupported div style #{style}"
          end
        end
      end
      file.write opening
      node.children.each.map { |c| visit(c, file) }
      file.write ending
    end
    # rubocop:enable Style/StringConcatenation

    # Download an image and return the saved file name.
    # def download_image(url) end

    def visit_sub(node, file)
      file.write '\textsubscript{'
      node.children.each.map { |c| visit(c, file) }
      file.write '}'
    end

    def visit_pre(node, file)
      if node.children.size == 1 and
         node.children[0].name == 'code'
        visit(node.children[0], file)
      else
        file.write "\n", '\begin{verbatim}', "\n"
        node.children.each.map { |c| visit(c, file) }
        file.write "\n", '\end{verbatim}', "\n"
      end
    end

    def visit_code(node, file)
      case node.attributes['class'].value
      when 'math'
        file.write '\['
        node.children.each.map { |c| visit(c, file) }
        file.write '\]'
      else
        raise "Unsupported code class #{node.attributes['class'].value}"
      end
    end

    def line_break(str, chars)
      words = str.split
      lines = []
      cur_line = ''
      until words.empty?
        if cur_line.size < chars
          cur_line += ' ' unless cur_line == ''
          cur_line += words.shift
        else
          lines << cur_line
          cur_line = ''
        end
      end
      lines << cur_line
      lines
    end

    # Return LaTeX code for the beginning of a chapter.
    def begin_chapter(title) end

    def transform_chapter(chapter_num)
      @chapter_has_underline = false
      @outside_double_quotes = true
      @outside_single_quotes = true
      chapter = @conf['story']['chapters'][chapter_num - 1]
      @logger.debug "Transforming chapter: #{chapter['number']} - #{chapter['title']}"
      doc = Nokogiri::HTML(File.open(chapter['html']))
      chapter['tex'] ||= @options.id + File::SEPARATOR +
                         File.basename(chapter['html'], '.html') + '.tex'
      File.open(chapter['tex'], 'wb') do |tex|
        tex.write(begin_chapter(latex_escape(chapter['title'])))
        build = StringIO.new
        visit_body(doc.at_xpath('/html/body'), build)
        @replacements.each do |src, dst|
          build.string.gsub!(src, dst)
        end
        tex.write build.string
      end
      unless @outside_double_quotes
        @logger.warn "Unbalanced quotation marks in chapter #{chapter['number']} - #{chapter['title']}"
        @warnings[:unbalanced_quotes][:chapters].append "#{chapter['number']} - #{chapter['title']}"
      end
      unless @outside_single_quotes
        @logger.warn "Unbalanced single quotation marks in chapter #{chapter['number']} - #{chapter['title']}"
        @warnings[:unbalanced_single_quotes][:chapters].append "#{chapter['number']} - #{chapter['title']}"
      end
      if @chapter_has_underline # rubocop:disable Style/GuardClause
        @logger.info "Chapter has underline: #{chapter['number']} - #{chapter['title']}"
        @warnings[:underline][:chapters].append "#{chapter['number']} - #{chapter['title']}"
      end
    end

    def transform_volume(num)
      volume = @volumes[num]
      @logger.debug "Transforming volume #{num + 1}, chapters #{volume['first']} - #{volume['last']}"

      vol_str = 'vol' + (num + 1).to_s + '-' # rubocop:disable Style/StringConcatenation

      File.open(@options.id + File::SEPARATOR + vol_str + 'chapters.tex', 'wb') do |chapters|
        @conf['story']['volumes'][num]['first'].upto(@conf['story']['volumes'][num]['last']) do |chapter_num|
          transform_chapter chapter_num
          chapter = @conf['story']['chapters'][chapter_num - 1]
          chapters.write "\\input{#{File.basename(chapter['tex'], '.tex')}}\n"
        end
      end
    end

    def transform
      @logger.debug 'Transforming story'

      @volumes.each_index { |num| transform_volume num }

      @warnings
    end

    def write_volume(num)
      @logger.debug "Writing LaTeX file for volume #{num + 1}"

      tmpl = @options.template.new
      File.open(@options.id + File::SEPARATOR + 'template.tex', 'wb') do |f|
        f.write tmpl.style
        f.write tmpl.chapter_style(@options.chapter_style)
        f.write tmpl.select_hr(@options.hr_style, @options.hr_symbol)
        f.write tmpl.select_underline(@options.underline)
      end
      File.open(@volumes[num]['tex_file'], 'wb') do |f|
        f.write "\\input{template}\n"
        f.write tmpl.volume_title(num + 1, @conf['story']['volumes'][num]['first'].to_i)
        f.write tmpl.header @conf['story']
        f.write tmpl.front_matter(@conf['story'], num + 1) if @options.front_matter
        f.write tmpl.toc if @options.toc
        f.write tmpl.body
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
      File.binwrite(@options.id + File::SEPARATOR + 'config.yaml', YAML.dump(@conf))
    end
  end
end
