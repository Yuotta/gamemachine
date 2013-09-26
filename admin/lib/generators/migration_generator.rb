require_relative 'generator_base'
require 'fileutils'
class MigrationGenerator < GeneratorBase

  attr_reader :name, :fields, :class_name

  class << self
    def create_all
      Component.all.each do |component|
        MigrationGenerator.new(component).create
      end
    end

    def destroy_all
      Component.all.each do |component|
        MigrationGenerator.new(component).destroy
      end
    end

    def migration_dir
      File.join( Rails.root, 'db', 'migrate')
    end

    def generated_migration_dir
      gen_migrations_path
    end

    def migrations
      Dir[File.join(migration_dir,"*.rb")]
    end

    def pending_migrations
      Dir[File.join(generated_migration_dir,"*.rb")]
    end

  end

  def destroy
    return false if has_migration?(:drop)
    if has_migration?(:create)
      action = 'destroy'
      @migration_name = "#{action}_#{@name}"
      @migration_class_name = "#{@name.camelize}"
      template = "migration_#{action}".to_sym
      write_migration(eval_template(template))
    end
  end

  def change(action,field)
    return false if has_migration?(:drop)
    if has_migration?(:create)
      @field = field
      action = action.to_s
      @migration_name = "#{action}_#{@name}_#{@field.name}"
      @migration_class_name = "#{@name.camelize}#{@field.name.camelize}"
      template = "migration_#{action}_column".to_sym
      write_migration(eval_template(template))
    end
  end

  def create
    return false if has_migration?(:create)
    @action = 'create'
    @migration_name = "#{@action}_#{@name}"
    write_migration(eval_template(:migration))
  end

  def has_migration?(type=:create,include_pending=true)
    if include_pending
      files = self.class.migrations + self.class.pending_migrations
    else
      files = self.class.migrations
    end
    files.each do |file|
      IO.readlines(file).each do |line|
        if line.match(/#{type}_table :#{@name_plural}/)
          return true
        end
      end
    end
    false
  end

  private

  def write_migration(content)
    File.open(migration_file,'w') {|f| f.write(content)}
  end

  def migration_ts
    sleep 1
    Time.now.to_s.split(" ")[0..1].join(" ").gsub!(/\D/, "")
  end

  def migration_file
    File.join(self.class.generated_migration_dir,"#{migration_ts}_#{@migration_name}.rb")
  end
end