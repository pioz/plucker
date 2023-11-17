# frozen_string_literal: true

require_relative 'lib/plucker/version'

Gem::Specification.new do |spec|
  spec.name = 'plucker'
  spec.version = Plucker::VERSION
  spec.authors = ['pioz']
  spec.email = ['epilotto@gmx.com']

  spec.summary = 'Pluck database records in structs.'
  spec.description = 'Plucker allows projecting a query into a specifically defined struct for the query.'
  spec.homepage = 'https://github.com/pioz/plucker'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  # spec.metadata['allowed_push_host'] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(/\Aexe\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'activerecord', '>= 5.0'
end
