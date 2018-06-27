require 'rails/generators/base'

  def todo(what)
    print "TODO>>> ", what ,"\n"
  end
  def gen_forien_key class_from,class_to
    print "CHECKPOINT>>> ",class_from,",",class_to,"\n"
    generate "migration", "add_#{class_to.tableize.downcase.singularize.downcase}_id_to#{class_to.tableize.downcase} #{class_to.tableize.downcase.singularize}:references" 
    
  end
  def do_add_relation (left_class,relation,right_class,option=nil,option_vars=[])
    params = [left_class,relation,right_class,option=nil,option_vars=[]]
    print "\n>>", params.join( "|"), "\n"
    left_class_file = File.join(Rails.root,"app/models/#{left_class.tableize.downcase.singularize}.rb")
    right_class_file= File.join(Rails.root,"app/models/#{right_class.tableize.downcase.singularize}.rb")
    print ">> ", right_class_file ,"\n"
    right_attribute_names = right_class.constantize.attribute_names.map{|n|n.downcase}
    left_attribute_names  =  left_class.constantize.attribute_names.map{|n|n.downcase}


    case  #2.2.1 make the changes in each cases
    when "has_one"===relation
      #when has_one the right class has a foriegn key to left class
      if ! right_attribute_names.include? "#{left_class.underscore}_id"
        gen_forien_key right_class,left_class
      end #生成外键完成

      inject_into_file left_class_file,after:"class #{left_class} < ApplicationRecord\n" do
        "  has_one :#{right_class.tableize.downcase.singularize}\n"
      end
      
    when "has_many"===relation
      #when has_many, the right class has a foriegn key to left class 
      if ! right_attribute_names.include? "#{left_class.underscore}_id"
        gen_forien_key right_class,left_class
      end #生成外键完成
      inject_into_file left_class_file,after:"class #{left_class} < ApplicationRecord\n" do
        "  has_many :#{right_class.tableize.downcase.singularize}\n"
      end

    when "belongs_to"===relation
      #when belongs_to the left clas has a foriegn key to right class
      if ! left_attribute_names.include? "#{right_class.underscore}_id"
        gen_forien_key left_class,right_class
      end #生成外键完成

      inject_into_file left_class_file,after:"class #{left_class} < ApplicationRecord\n" do
        "  belongs_to :#{right_class.tableize.downcase.singularize}\n"
      end
    when "many_to_many"===relation
      if left_class === right_class
        #todo 如果左右的类是同一个，多对多就会出问题。 
        todo "Self Joins are not suported by now. you must do it manually 
              2.10 Self Joins
                In designing a data model, you will sometimes find a model that should have a relation to itself. For example, you may want to store all employees in a single database model, but be able to trace relationships such as between manager and subordinates. This situation can be modeled with self-joining associations:

                class Employee < ApplicationRecord
                  has_many :subordinates, class_name: \"Employee\",
                                          foreign_key: \"manager_id\"
                
                  belongs_to :manager, class_name: \"Employee\"
                end
                With this setup, you can retrieve @employee.subordinates and @employee.manager.

                In your migrations/schema, you will add a references column to the model itself.

                class CreateEmployees < ActiveRecord::Migration[5.0]
                  def change
                    create_table :employees do |t|
                      t.references :manager, index: true
                      t.timestamps
                    end
                  end
                end"
        return
      else
      end
      if ["through","join_by","join_model"].include? option
        join_model = option_vars.shift
      else
        if !option_vars.empty?
          join_model = option_vars.shift
        else
          join_model = "#{left_class.tableize.downcase.singularize}_#{right_class.tableize}"
        end
        join_model = join_model.tableize.singularize
        generate "model","#{join_model} #{left_class.tableize.downcase.singularize}:references #{right_class.tableize.downcase.singularize}:references #{option_vars.join(" ")}"
      end
      join_class = join_model.classify
      join_attribute_names = join_class.constantize.attribute_names.map{|n| n.downcase}
      #when many to many the join model must has both foriegn key to right and left class
      if ! join_attribute_names.include? "#{left_class.underscore}_id"
        gen_forien_key join_class,left_class
      end 
      if ! join_attribute_names.include? "#{right_class.underscore}_id"
        gen_forien_key join_class,right_class
      end #生成外键完成
      join_model_file = File.join(Rails.root,"app/models/#{join_model}.rb")
      inject_into_file join_model_file,after:"class #{join_class}  < ApplicationRecord\n" do
        "  belongs_to :#{left_class.tableize.downcase.singularize}\n  belongs_to :#{right_class.tableize.downcase.singularize}\n"
      end
      inject_into_file left_class_file,after:"class #{left_class} < ApplicationRecord\n" do
        "  has_many :#{join_model}\n  has_many :#{right_class.tableize.downcase.pluralize}, :through => :#{join_model}\n"
      end
      inject_into_file right_class_file,after:"class #{right_class} < ApplicationRecord\n" do
        "  has_many :#{join_model}\n  has_many :#{left_class.tableize.downcase.pluralize}, :through => :#{join_model}\n"
      end
    else
      print "ERROR:unknow relationship:#{relation}. going to die\n" 
      #die
    end 
  end
  
  class AssoGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  argument :relations, :type => :array, :default => [], :banner => "action action"
  
  # the api will be:
  # rails g asso user \
  #    has_one:avatar \
  #    has_many:docs:belongs_to_me \
  #    belongs_to:house \
  #    belongs_to:dark_lord:has_one_me \
  #    many_to_many:schools \
  #    many_to_many:users:through:friendship 
  #    many_to_many:doctor:through_with_extra:apointment:start_at,datetime:end_at,datetime
  #options 

  
  def make_relations
    
    require 'active_support'
    #1. check left class is there. die if none.
    left_class = class_name
    #todo just die now
    print "Makeing relations of <#{left_class}>:\n"
    left_object = left_class.constantize 
    #2.  for each relation do:
    jobs=[]
    relations.each do | relation |
      the_left_class = left_class
      relation,right_class,option,*option_vars = relation.split ":"
      right_class = right_class.singularize.camelcase
      #print "\n>",relation,",",right_class,",",option,",",option_vars,"\n"
      #2.1 check if the models is there. die if none.
      #todo just die now
      right_obj   = right_class.constantize

      #2.1 check if the relations is made already.
      # todo, later
      #2.2 detemine what relation it will be. add reverse relations to jobs
      print "found ", relation," to ",right_class,"\n"
      do_add_relation(the_left_class,relation,right_class,option,option_vars)
      if ["has_one_me","has_me_only","has_only_me","has_one"].include? option 
        relation="has_one"
        right_class,the_left_class=the_left_class,right_class #swap left and right
        do_add_relation(the_left_class,relation,right_class,option,option_vars)
      end
      if ["belongs_to_me"].include? option
        relation="belongs_to"
        right_class,the_left_class=the_left_class,right_class #swap left and right
        do_add_relation(the_left_class,relation,right_class,option,option_vars)
      end

    end 

    
  end
  
end
