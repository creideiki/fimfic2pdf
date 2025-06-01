# frozen_string_literal: true

require 'spec_helper'

require 'ao32book'
require 'ao32novel'

RSpec.shared_examples 'AO32PDF', :order => :defined do # rubocop:disable Metrics/BlockLength
  it 'has a version number' do
    expect(FiMFic2PDF::VERSION).to be_a String
  end

  before(:context) do
    @old_cwd = Dir.getwd
    @temp_dir = Dir.mktmpdir 'fimfic2pdf_spec'
    Dir.chdir @temp_dir

    FileUtils.mkdir TEST_ID
    FileUtils.copy_file("#{SAMPLE_PATH}/lorem-ipsum_ao3.epub",
                        "#{TEST_ID}/lorem-ipsum_ao3.epub")
  end

  example 'downloader handles a pre-placed epub file' do
    downloader = described_class::Downloader.new TEST_ID
    epub_found = downloader.manually_downloaded?

    expect(epub_found).to eq true

    downloader.unpack

    files = Dir.children TEST_ID
    expect(files).to contain_exactly 'lorem-ipsum_ao3.epub',
                                     'Lorem_Ipsum_split_000.xhtml', 'Lorem_Ipsum_split_001.xhtml',
                                     'Lorem_Ipsum_split_002.xhtml', 'Lorem_Ipsum_split_003.xhtml',
                                     'Lorem_Ipsum_split_004.xhtml', 'content.opf', 'toc.ncx'

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
        'html'   => "#{TEST_ID}/Lorem_Ipsum_split_002.xhtml"
      },
      {
        'number' => 2,
        'title'  => 'Ipsum',
        'html'   => "#{TEST_ID}/Lorem_Ipsum_split_003.xhtml"
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
    expect(files).to include 'vol1-chapters.tex', 'Lorem_Ipsum_split_002.xhtml.tex', 'Lorem_Ipsum_split_003.xhtml.tex'

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

RSpec.describe FiMFic2PDF::AO32Book do
  include_examples 'AO32PDF'
end

RSpec.describe FiMFic2PDF::AO32Novel do
  include_examples 'AO32PDF'
end
