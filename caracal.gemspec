# -*- encoding: utf-8 -*-
# stub: caracal 1.7.2 ruby lib

Gem::Specification.new do |s|
  s.name = "caracal".freeze
  s.version = "1.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Trade Infomatics".freeze, "John Dugan".freeze, "Sprengnetter Real Estate", "Willem van Kerkhof", "Kuba Kuzma"]
  s.date = "2022-01-26"
  s.description = " Caracal is a pure Ruby Microsoft Word generation library that produces professional quality MSWord documents (docx) using a simple, HTML-style DSL. ".freeze
  s.email = ["jpdugan@gmail.com".freeze, "willem.van-kerkhof@innoq.com".freeze]

  s.files = Dir["{lib,spec}/**/*", "Rakefile", "README.md", "CHANGELOG.md", "Gemfile", "LICENSE.txt", "caracal.gemspec"]
  s.homepage = "https://github.com/sprengnetter/caracal".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.3".freeze
  s.summary = "Fast, professional Microsoft Word (docx) writer for Ruby.".freeze
  s.test_files = ["spec/lib/caracal/core/bookmarks_spec.rb".freeze, "spec/lib/caracal/core/file_name_spec.rb".freeze, "spec/lib/caracal/core/fonts_spec.rb".freeze, "spec/lib/caracal/core/iframes_spec.rb".freeze, "spec/lib/caracal/core/ignorables_spec.rb".freeze, "spec/lib/caracal/core/images_spec.rb".freeze, "spec/lib/caracal/core/list_styles_spec.rb".freeze, "spec/lib/caracal/core/lists_spec.rb".freeze, "spec/lib/caracal/core/models/base_model_spec.rb".freeze, "spec/lib/caracal/core/models/bookmark_model_spec.rb".freeze, "spec/lib/caracal/core/models/border_model_spec.rb".freeze, "spec/lib/caracal/core/models/font_model_spec.rb".freeze, "spec/lib/caracal/core/models/iframe_model_spec.rb".freeze, "spec/lib/caracal/core/models/image_model_spec.rb".freeze, "spec/lib/caracal/core/models/line_break_model_spec.rb".freeze, "spec/lib/caracal/core/models/link_model_spec.rb".freeze, "spec/lib/caracal/core/models/list_item_model_spec.rb".freeze, "spec/lib/caracal/core/models/list_model_spec.rb".freeze, "spec/lib/caracal/core/models/list_style_model_spec.rb".freeze, "spec/lib/caracal/core/models/margin_model_spec.rb".freeze, "spec/lib/caracal/core/models/namespace_model_spec.rb".freeze, "spec/lib/caracal/core/models/page_break_model_spec.rb".freeze, "spec/lib/caracal/core/models/page_number_model_spec.rb".freeze, "spec/lib/caracal/core/models/page_size_model_spec.rb".freeze, "spec/lib/caracal/core/models/paragraph_model_spec.rb".freeze, "spec/lib/caracal/core/models/relationship_model_spec.rb".freeze, "spec/lib/caracal/core/models/rule_model_spec.rb".freeze, "spec/lib/caracal/core/models/style_model_spec.rb".freeze, "spec/lib/caracal/core/models/table_cell_model_spec.rb".freeze, "spec/lib/caracal/core/models/table_model_spec.rb".freeze, "spec/lib/caracal/core/models/table_of_content_model_spec.rb".freeze, "spec/lib/caracal/core/models/text_model_spec.rb".freeze, "spec/lib/caracal/core/namespaces_spec.rb".freeze, "spec/lib/caracal/core/page_breaks_spec.rb".freeze, "spec/lib/caracal/core/page_numbers_spec.rb".freeze, "spec/lib/caracal/core/page_settings_spec.rb".freeze, "spec/lib/caracal/core/relationships_spec.rb".freeze, "spec/lib/caracal/core/rules_spec.rb".freeze, "spec/lib/caracal/core/styles_spec.rb".freeze, "spec/lib/caracal/core/table_of_contents_spec.rb".freeze, "spec/lib/caracal/core/tables_spec.rb".freeze, "spec/lib/caracal/core/text_spec.rb".freeze, "spec/lib/caracal/errors_spec.rb".freeze, "spec/lib/caracal/view_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/support/_fixtures/snippet.docx".freeze]

  s.installed_by_version = "3.3.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    if RUBY_VERSION.to_f >= 3.3
      # fixes deprecation, ostruct will be removed from ruby 3.4
      s.add_runtime_dependency(%q<ostruct>.freeze, ["~> 0.6"])
    end
    s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
    s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 1.1.0", "< 3.0"])
    s.add_runtime_dependency(%q<tilt>.freeze, [">= 1.4"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
  else
    if RUBY_VERSION.to_f >= 3.3
      # fixes deprecation, ostruct will be removed from ruby 3.4
      s.add_dependency(%q<ostruct>.freeze, ["~> 0.6"])
    end
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.6"])
    s.add_dependency(%q<rubyzip>.freeze, [">= 1.1.0", "< 3.0"])
    s.add_dependency(%q<zip-zip>.freeze, [">= 1.0.0"])
    s.add_dependency(%q<tilt>.freeze, [">= 1.4"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end
