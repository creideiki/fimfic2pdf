# frozen_string_literal: true

require_relative 'lib/fimfic2pdf/version'

Gem::Specification.new do |s|
  s.name = 'fimfic2pdf'
  s.version = FiMFic2PDF::VERSION
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0'
  s.authors = ['Karl-Johan Karlsson']
  s.email = ['creideiki@ferretporn.se']
  s.description = <<-DESCRIPTION
    FiMFic2PDF converts stories from FiMFiction.net or
    ArchiveOfOurOwn.org into PDF format, for reading on screen or
    print-on-demand publication.
  DESCRIPTION

  s.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH)
  s.bindir = 'exe'
  s.executables = ['fimfic2book', 'fimfic2novel',
                   'ao32book', 'ao32novel']
  s.extra_rdoc_files = ['COPYING']
  s.homepage = 'https://github.com/creideiki/fimfic2pdf/'
  s.licenses = ['GPL-3.0']
  s.summary = 'Formats FiMFiction stories as PDF.'

  s.metadata = {
    'homepage_uri'    => 'https://github.com/creideiki/fimfic2pdf/',
    'source_code_uri' => 'https://github.com/creideiki/fimfic2pdf/',
    'bug_tracker_uri' => 'https://github.com/creideiki/fimfic2pdf/issues'
  }

  s.add_runtime_dependency('httparty', '~> 0.21')
  s.add_runtime_dependency('nokogiri', '~> 1.15')
  s.add_runtime_dependency('rubyzip', '~> 2.3')

  s.add_development_dependency('bundler', '~> 2.4')
  s.add_development_dependency('rubocop', '~> 1.42')
  s.add_development_dependency('rubocop-rake', '~> 0.6')
end
