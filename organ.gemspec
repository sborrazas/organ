Gem::Specification.new do |s|
  s.name = "organ"
  s.version = "0.1.0"
  s.summary = "Forms with integrated validations and attribute coercing."
  s.description = "A small library for manipulating form-based data with validations and attributes coercion."
  s.authors = ["Sebastian Borrazas"]
  s.email = ["seba.borrazas@gmail.com"]
  s.homepage = "http://github.com/sborrazas/organ"
  s.license = "MIT"

  s.files = Dir[
    "LICENSE",
    "README.md",
    "Rakefile",
    "lib/**/*.rb",
    "*.gemspec",
    "spec/*.*"
  ]

  s.require_paths = ["lib"]
end
