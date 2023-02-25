# frozen_string_literal: true

require 'fimfic2pdf/novel/template'

module FiMFic2PDF
  module Book
    # Transforms HTML documents to LaTeX for the Novel class
    module Transformer
      def span_open(style)
        case style
        when 'font-size:2em'
          '\begin{LARGE}'
        when 'font-size:1.5em'
          '\begin{Large}'
        when 'font-size:0.875em', 'font-size:0.8125em'
          '\begin{small}'
        when 'font-size:0.75em'
          '\begin{footnotesize}'
        when 'font-size:0.5em'
          '\begin{scriptsize}'
        when 'text-decoration:line-through'
          '\sout{'
        when 'text-decoration:underline line-through'
          if @in_blockquote
            '\sout{'
          else
            @chapter_has_underline = true
            '\fancyuline{\sout{'
          end
        else
          super
        end
      end

      def span_close(style)
        case style
        when 'font-size:2em'
          '\end{LARGE}'
        when 'font-size:1.5em'
          '\end{Large}'
        when 'font-size:0.875em', 'font-size:0.8125em'
          '\end{small}'
        when 'font-size:0.75em'
          '\end{footnotesize}'
        when 'font-size:0.5em'
          '\end{scriptsize}'
        when 'text-decoration:line-through'
          '}'
        when 'text-decoration:underline line-through'
          if @in_blockquote
            '}'
          else
            '}}'
          end
        else
          super
        end
      end

      def visit_plain_blockquote(node, file)
        previous_blockquote = @in_blockquote
        @in_blockquote = true
        file.write "\n", '\begin{quotation}', "\n"
        file.write '\cbstart', "\n" if @options.barred_blockquotes
        node.children.each.map { |c| visit(c, file) }
        file.write "\n", '\cbend' if @options.barred_blockquotes
        file.write "\n", '\end{quotation}', "\n"
        @in_blockquote = previous_blockquote
      end

      def visit_s(node, file)
        file.write '\sout{'
        node.children.each.map { |c| visit(c, file) }
        file.write '}'
      end

      def visit_strike(node, file)
        file.write '\sout{'
        node.children.each.map { |c| visit(c, file) }
        file.write '}'
      end

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

      def begin_chapter(title)
        "\\chapter{#{title}}\n\n"
      end
    end
  end
end
