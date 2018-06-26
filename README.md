# AssoGenerator
This rails generator will generate associations between models. 
using command lines like:

rails g asso user  \
   has_one:avatar:belongs_to_me \
   has_many:docs \
   many_to_many:dark_lords:through:friendship \
   belongs_to:house many_to_many:school

   rails g asso user \
      has_one:avatar \
      has_many:docs:belongs_to_me \
      belongs_to:house \
      belongs_to:dark_lord:has_one_me \
      many_to_many:schools \
      many_to_many:users:through:friendship 
      many_to_many:doctor:through_with_extra:apointment:start_at,datetime:end_at,datetime
      
== TODO
  1. a proper document
  2. many to many relation of self.
