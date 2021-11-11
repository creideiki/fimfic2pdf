# frozen_string_literal: true

require_relative 'lib/fimfic2pdf/version'

Gem::Specification.new do |s|
  s.name = 'fimfic2pdf'
  s.version = FimFic2PDF::VERSION
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0'
  s.authors = ['Karl-Johan Karlsson']
  s.email = ['creideiki@ferretporn.se']
  s.description = <<-DESCRIPTION
    FimFic2PDF converts stories from FimFiction.net into PDF format,
    primarily for publication on Lulu.
  DESCRIPTION

  s.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH)
  s.bindir = 'exe'
  s.executables = ['fimfic2pdf']
  s.extra_rdoc_files = ['COPYING']
  s.homepage = 'https://github.com/creideiki/fimfic2pdf/'
  s.licenses = ['GPL-3.0']
  s.summary = 'Formats FimFiction stories as PDF.'

  s.metadata = {
    'homepage_uri' => 'https://github.com/creideiki/fimfic2pdf/',
    'source_code_uri' => 'https://github.com/creideiki/fimfic2pdf/',
    'bug_tracker_uri' => 'https://github.com/creideiki/fimfic2pdf/issues'
  }

  s.add_runtime_dependency('httparty', '~> 0.20')
  s.add_runtime_dependency('nokogiri', '~> 1.12')
  s.add_runtime_dependency('ruby-progressbar', '~> 1.11')
  s.add_runtime_dependency('rubyzip', '~> 2.3')

  s.add_development_dependency('bundler', '~> 2.2')
  s.add_development_dependency('rubocop', '~> 1.22')
  s.add_development_dependency('rubocop-rake', '~> 0.6')
end
