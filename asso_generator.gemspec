$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "asso_generator"
  s.version     = "0.4"
  s.platform    = "ruby"
  s.authors     = ["Vincent Luc"]
  s.email       = ["hotvulcan@gmail.com"]
  s.homepage    = "https://github.com/hotvulcan/asso_generator"
  s.summary     = %q{A rails generator to generate associations between models.}
  s.description = %q{This rails generator will generate associations between models. giving the command line:
   rails g asso user 
      has_one:avatar 
      has_many:docs:belongs_to_me 
      belongs_to:house 
      belongs_to:dark_lord:has_one_me 
      many_to_many:schools 
      many_to_many:users:through:friendship 
      many_to_many:doctor:through_with_extra:apointment:start_at,datetime:end_at,datetime
   
    }
  s.files = Dir.glob("{lib}/**/*")
  s.require_path = 'lib'
  s.add_development_dependency 'rails', '~> 5.2', '>= 5.2.0'
  s.licenses = "BSD-2-Clause"
  
end