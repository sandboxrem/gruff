# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "gruff"
  s.version = "0.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Geoffrey Grosenbach"]
  s.date = "2009-08-21"
  s.description = "Beautiful graphs for one or multiple datasets. Can be used on websites or in documents."
  s.email = "boss@topfunky.com"
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt"]
  s.homepage = "http://nubyonrails.com/pages/gruff"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "gruff"
  s.rubygems_version = "1.8.10"
  s.summary = "Beautiful graphs for one or multiple datasets."

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.12.1"])
    else
      s.add_dependency(%q<hoe>, [">= 1.12.1"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.12.1"])
  end
end
