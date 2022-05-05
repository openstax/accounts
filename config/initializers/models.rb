ActiveRecord::Base.class_exec do

  def association_attributes(associations = [],
                             slice: nil,
                             except: nil,
                             exclude_foreign_keys: false,
                             transform_arrays_into_sets: false)
    attrs = attributes
    attrs = attrs.slice(*slice) if slice.present?
    attrs = attrs.except(*except) if except.present?

    if exclude_foreign_keys
      foreign_keys = self.class.reflect_on_all_associations(:belongs_to).map(&:foreign_key)
      attrs        = attrs.except(*foreign_keys)
    end

    [associations].flatten.compact.each_with_object(attrs) do |association, hash|
      association = [association].flatten.compact unless association.respond_to?(:each)

      association.each do |name, subtree|
        objects = send(name)
        next if objects.nil?

        if objects.respond_to?(:collect)
          hash[name.to_s] = objects.collect do |object|
            object.association_attributes(
              subtree,
              slice:                      slice,
              except:                     except,
              exclude_foreign_keys:       exclude_foreign_keys,
              transform_arrays_into_sets: transform_arrays_into_sets
            )
          end

          hash[name.to_s] = Set.new(hash[name.to_s]) if transform_arrays_into_sets
        else
          hash[name.to_s] = objects.association_attributes(
            subtree,
            slice:                      slice,
            except:                     except,
            exclude_foreign_keys:       exclude_foreign_keys,
            transform_arrays_into_sets: transform_arrays_into_sets
          )
        end
      end
    end
  end

end
