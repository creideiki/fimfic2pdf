# frozen_string_literal: true

require 'spec_helper'

require 'fimfic2pdf/ao3_book/transformer'
require 'fimfic2pdf/ao3_novel/transformer'
require 'fimfic2pdf/fimfic_book/transformer'
require 'fimfic2pdf/fimfic_novel/transformer'

require 'yaml'
require 'nokogiri'

RSpec.shared_examples 'transformer' do # rubocop:disable Metrics/BlockLength
  before(:context) do
    @old_cwd = Dir.getwd
    @temp_dir = Dir.mktmpdir 'fimfic2pdf_spec'
    Dir.chdir @temp_dir

    FileUtils.mkdir TEST_ID
    test_conf = { 'story' => { 'id' => TEST_ID } }
    File.binwrite("#{TEST_ID}/config.yaml", YAML.dump(test_conf))
  end

  it 'detects unbalanced double quotes' do
    FileUtils.copy_file("#{SAMPLE_PATH}/unbalanced-double-quotes.html",
                        "#{TEST_ID}/unbalanced-double-quotes.html")

    options = OpenStruct.new(:id              => TEST_ID,
                             :prettify_quotes => true)
    transformer = described_class::Transformer.new options

    doc = Nokogiri::HTML(File.open("#{TEST_ID}/unbalanced-double-quotes.html"))
    tex = StringIO.new
    transformer.outside_double_quotes = true
    transformer.visit(doc.at_xpath('/html/body/p'), tex)

    expect(transformer.outside_double_quotes).to eq false
  end

  it 'detects unbalanced single quotes' do
    FileUtils.copy_file("#{SAMPLE_PATH}/unbalanced-single-quotes.html",
                        "#{TEST_ID}/unbalanced-single-quotes.html")

    options = OpenStruct.new(:id                     => TEST_ID,
                             :prettify_single_quotes => true)
    transformer = described_class::Transformer.new options

    doc = Nokogiri::HTML(File.open("#{TEST_ID}/unbalanced-single-quotes.html"))
    tex = StringIO.new
    transformer.outside_single_quotes = true
    transformer.visit(doc.at_xpath('/html/body/p'), tex)

    expect(transformer.outside_single_quotes).to eq false
  end

  it 'generates errors for unknown HTML tags' do
    FileUtils.copy_file("#{SAMPLE_PATH}/unknown-html-tag.html",
                        "#{TEST_ID}/unknown-html-tag.html")

    options = OpenStruct.new(:id => TEST_ID)
    transformer = described_class::Transformer.new options

    doc = Nokogiri::HTML(File.open("#{TEST_ID}/unknown-html-tag.html"))
    tex = StringIO.new
    expect { # rubocop:disable Style/BlockDelimiters
      transformer.visit(doc.at_xpath('/html/body/p'), tex)
    }.to raise_error(RuntimeError, 'Unsupported HTML element fake')
  end

  it 'tests all known HTML tags' do
    FileUtils.copy_file("#{SAMPLE_PATH}/all-html-tags.html",
                        "#{TEST_ID}/all-html-tags.html")

    options = OpenStruct.new(:id => TEST_ID)
    transformer = described_class::Transformer.new options

    tested_tags = transformer.methods.grep(/^visit_/) - [:visit_body]
    tested_tags.each do |tag_method|
      expect(transformer).to receive(tag_method).at_least(:once).and_call_original
    end

    allow(transformer).to receive(:download_image).and_return('mock_image.jpg')

    doc = Nokogiri::HTML(File.open("#{TEST_ID}/all-html-tags.html"))
    tex = StringIO.new
    transformer.visit(doc.at_xpath('/html/body/div'), tex)
  end

  after(:context) do
    Dir.chdir @old_cwd
    FileUtils.rmtree @temp_dir
  end
end

RSpec.describe FiMFic2PDF::AO32Book do
  include_examples 'transformer'
end

RSpec.describe FiMFic2PDF::AO32Novel do
  include_examples 'transformer'
end

RSpec.describe FiMFic2PDF::FiMFic2Book do
  include_examples 'transformer'
end

RSpec.describe FiMFic2PDF::FiMFic2Novel do
  include_examples 'transformer'
end
