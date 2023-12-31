# frozen_string_literal: true

require 'spec_helper'

require 'fimfic2book'
require 'fimfic2novel'

RSpec.shared_examples 'FiMFic2PDF', :order => :defined do # rubocop:disable Metrics/BlockLength
  it 'has a version number' do
    expect(FiMFic2PDF::VERSION).to be_a String
  end

  before(:context) do
    @old_cwd = Dir.getwd
    @temp_dir = Dir.mktmpdir 'fimfic2pdf_spec'
    Dir.chdir @temp_dir

    FileUtils.mkdir TEST_ID
    FileUtils.copy_file("#{SAMPLE_PATH}/lorem-ipsum_fimfic.epub",
                        "#{TEST_ID}/#{TEST_ID}.epub")
  end

  example 'downloader handles a pre-placed epub file' do
    downloader = described_class::Downloader.new TEST_ID
    epub_found = downloader.manually_downloaded?

    expect(epub_found).to eq true

    downloader.unpack

    files = Dir.children TEST_ID
    expect(files).to contain_exactly '12345.epub', 'chapter-1.html', 'chapter-2.html',
                                     'title.html', 'toc.html', 'book.opf'

    downloader.write_config
  end

  example 'transformer generates LaTeX files' do # rubocop:disable Metrics/BlockLength
    options = OpenStruct.new(:id => TEST_ID, :template => described_class::Template)

    transformer = described_class::Transformer.new options
    transformer.parse_metadata

    expect(transformer.conf['story']['title']).to eq 'FiMFic2PDF Example Document'
    expect(transformer.conf['story']['author']).to eq 'Creideiki'
    chapters = [
      {
        'number' => 1,
        'title'  => 'Lorem',
        'html'   => "#{TEST_ID}/chapter-1.html"
      },
      {
        'number' => 2,
        'title'  => 'Ipsum',
        'html'   => "#{TEST_ID}/chapter-2.html"
      }
    ]
    expect(transformer.conf['story']['chapters']).to have_structure chapters

    transformer.prepare_volumes

    volumes = [
      {
        'first'    => 1,
        'last'     => 2,
        'number'   => 1,
        'tex_file' => "#{TEST_ID}/creideiki-fimfic2pdf_example_document-1.tex",
        'aux_file' => "#{TEST_ID}/creideiki-fimfic2pdf_example_document-1.aux",
        'pdf_file' => "#{TEST_ID}/creideiki-fimfic2pdf_example_document-1.pdf"
      }
    ]
    expect(transformer.conf['story']['volumes']).to have_structure volumes

    expect { transformer.validate_volumes }.not_to raise_error

    warnings = transformer.transform

    expect(warnings[:underline][:chapters]).to contain_exactly '1 - Lorem'
    expect(warnings[:unbalanced_quotes][:chapters]).to be_empty
    expect(warnings[:unbalanced_single_quotes][:chapters]).to be_empty

    if described_class.to_s.end_with? 'Novel'
      expect(warnings[:font_size][:chapters]).to contain_exactly '1 - Lorem'
      expect(warnings[:list][:chapters]).to be_empty
    end

    files = Dir.children TEST_ID
    expect(files).to include 'vol1-chapters.tex', 'chapter-1.tex', 'chapter-2.tex'

    transformer.write_story

    files = Dir.children TEST_ID
    expect(files).to include 'template.tex', 'creideiki-fimfic2pdf_example_document-1.tex'

    transformer.write_config
  end

  after(:context) do
    Dir.chdir @old_cwd
    FileUtils.rmtree @temp_dir
  end
end

RSpec.describe FiMFic2PDF::FiMFic2Book do
  include_examples 'FiMFic2PDF'
end

RSpec.describe FiMFic2PDF::FiMFic2Novel do
  include_examples 'FiMFic2PDF'
end
