# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "my-lib"
  s.version = "0.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["modeverv"]
  s.date = "2012-01-09"
  s.description = "longer description of your gem"
  s.email = "modeverv@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "TAGS",
    "VERSION",
    "lib/1.rb",
    "lib/lib/job.rb",
    "lib/lib/machine.rb",
    "lib/lib/myat.rb",
    "lib/lib/myconfig.rb",
    "lib/lib/mydb.rb",
    "lib/lib/mygcal.rb",
    "lib/lib/mylogger.rb",
    "lib/lib/myobject.rb",
    "lib/lib/mypusher.rb",
    "lib/lib/runpersec.rb",
    "lib/my-lib.rb",
    "my-lib.gemspec",
    "spec/my-lib_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/modeverv/my-lib"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "one-line summary of your gem"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<term-ansicolor>, [">= 0"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
      s.add_runtime_dependency(%q<mechanize>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["> 2.3.0"])
      s.add_development_dependency(%q<yard>, ["> 0.6.0"])
      s.add_development_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<guard>, [">= 0"])
      s.add_development_dependency(%q<guard-spork>, [">= 0"])
    else
      s.add_dependency(%q<term-ansicolor>, [">= 0"])
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<mechanize>, [">= 0"])
      s.add_dependency(%q<rspec>, ["> 2.3.0"])
      s.add_dependency(%q<yard>, ["> 0.6.0"])
      s.add_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<guard>, [">= 0"])
      s.add_dependency(%q<guard-spork>, [">= 0"])
    end
  else
    s.add_dependency(%q<term-ansicolor>, [">= 0"])
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<mechanize>, [">= 0"])
    s.add_dependency(%q<rspec>, ["> 2.3.0"])
    s.add_dependency(%q<yard>, ["> 0.6.0"])
    s.add_dependency(%q<bundler>, ["> 1.0.0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<guard>, [">= 0"])
    s.add_dependency(%q<guard-spork>, [">= 0"])
  end
end

