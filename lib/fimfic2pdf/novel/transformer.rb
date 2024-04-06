# frozen_string_literal: true

module FiMFic2PDF
  module Novel
    # Transforms HTML documents to LaTeX for the Novel class
    module Transformer
      def initialize(options)
        super

        @warnings[:font_size] = {
          chapters: [],
          message: 'Font size changes present in the following chapters. ' \
                   'Please check formatting manually, ' \
                   'make any changes to the LaTeX files, and re-run without "--retransform".'
        }

        @warnings[:list] = {
          chapters: [],
          message: 'Lists present in the following chapters. ' \
                   'The "novel" document class does not handle lists. ' \
                   'Converted to plain text.'
        }
      end

      def span_open(style)
        case style
        when /^font-size:([[:digit:].]+)em/
          @chapter_changes_font_size = true
          "\\charscale[#{::Regexp.last_match(1)}]{"
        when 'text-decoration:line-through'
          '\strikeThrough{'
        when 'text-decoration:underline line-through'
          @chapter_has_underline = true
          '\fancyuline{\strikeThrough{'
        else
          super
        end
      end

      def span_close(style)
        case style
        when /^font-size:([[:digit:].]+)em/
          '}'
        when 'text-decoration:line-through' # rubocop:disable Lint/DuplicateBranch
          '}'
        when 'text-decoration:underline line-through'
          '}}'
        else
          super
        end
      end

      def visit_u(node, file)
        file.write '\fancyuline{'
        @chapter_has_underline = true
        node.children.each.map { |c| visit(c, file) }
        file.write '}'
      end

      def visit_plain_blockquote(node, file)
        previous_blockquote = @in_blockquote
        @in_blockquote = true
        file.write "\n"
        file.write('\vspace{\nbs}', "\n") if node&.previous&.name != 'hr'
        file.write '\begin{adjustwidth}{3em}{3em}', "\n"
        node.children.each.map { |c| visit(c, file) }
        file.write "\n", '\end{adjustwidth}'
        file.write("\n", '\vspace{\nbs}') if node&.next&.name != 'hr'
        file.write "\n"
        @in_blockquote = previous_blockquote
      end

      def visit_s(node, file)
        file.write '\strikeThrough{'
        node.children.each.map { |c| visit(c, file) }
        file.write '}'
      end

      def visit_strike(node, file)
        file.write '\strikeThrough{'
        node.children.each.map { |c| visit(c, file) }
        file.write '}'
      end

      def visit_h1(node, file)
        file.write "\n", '\charscale[2.0]{'
        node.children.each.map { |c| visit(c, file) }
        file.write '}', "\n"
      end

      def visit_h2(node, file)
        file.write "\n", '\charscale[1.5]{'
        node.children.each.map { |c| visit(c, file) }
        file.write '}', "\n"
      end

      def visit_ul(node, file)
        @chapter_has_list = true
        @list_counters.push :ul
        file.write "\n"
        node.children.each.map { |c| visit(c, file) }
        file.write "\n"
        @list_counters.pop
      end

      def visit_ol(node, file)
        @chapter_has_list = true
        @list_counters.push 0
        file.write "\n"
        node.children.each.map { |c| visit(c, file) }
        file.write "\n"
        @list_counters.pop
      end

      def visit_li(node, file)
        @chapter_has_list = true
        counter = @list_counters.pop
        if counter == :ul
          @list_counters.push counter
          file.write "\n", '● '
        else # integer
          counter += 1
          file.write "\n", "#{counter}. "
          @list_counters.push counter
        end
        node.children.each.map { |c| visit(c, file) }
        file.write "\n"
      end

      def visit_img(node, file)
        url = node.attributes['src'].value
        filename = download_image url
        file.write "\n\\FloatImage[ht,0,-\\normalXheight]{#{filename}}\n"
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

      def begin_chapter(title)
        s  = "\n\\clearpage"
        s += "\n\\begin{ChapterStart}"
        line_break(title, 30).each do |line|
          s += "\n\\ChapterTitle[c]{#{line}}\n"
        end
        s += "\n\\end{ChapterStart}"
        s
      end

      def transform_chapter(chapter_num)
        @chapter_changes_font_size = false
        @chapter_has_list = false
        @list_counters = []

        super

        if @chapter_changes_font_size
          chapter = @conf['story']['chapters'][chapter_num - 1]
          @logger.info "Chapter changes font size: #{chapter['number']} - #{chapter['title']}"
          @warnings[:font_size][:chapters].append "#{chapter['number']} - #{chapter['title']}"
        end

        if @chapter_has_list # rubocop:disable Style/GuardClause
          chapter = @conf['story']['chapters'][chapter_num - 1]
          @logger.info "Chapter contains list: #{chapter['number']} - #{chapter['title']}"
          @warnings[:list][:chapters].append "#{chapter['number']} - #{chapter['title']}"
        end
      end
    end
  end
end
