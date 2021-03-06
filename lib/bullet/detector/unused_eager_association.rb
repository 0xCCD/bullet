module Bullet
  module Detector
    class UnusedEagerAssociation < Association
      class <<self
        # check if there are unused preload associations.
        #   get related_objects from eager_loadings associated with object and associations
        #   get call_object_association from associations of call_object_associations whose object is in related_objects
        #   if association not in call_object_association, then the object => association - call_object_association is ununsed preload assocations
        def check_unused_preload_associations
          @@checked = true
          object_associations.each do |object_ar_key, association|
            object_association_diff = diff_object_association object_ar_key, association
            next if object_association_diff.empty?

            create_notification object_ar_key.split(":").first, object_association_diff
          end
        end

        private
          def create_notification(klazz, associations)
            notice = Bullet::Notification::UnusedEagerLoading.new(klazz, associations)
            Bullet.notification_collector.add(notice)
          end

          def call_associations(object_ar_key, association)
            all = Set.new
            eager_loadings.similarly_associated(object_ar_key, association).each do |related_object_ar_key|
              coa = call_object_associations[related_object_ar_key]
              next if coa.nil?
              all.merge coa
            end
            all.to_a
          end

          def diff_object_association(object_ar_key, association)
            potential_objects = association - call_associations(object_ar_key, association)
            potential_objects.reject { |a| a.is_a?(Hash) }
          end
      end
    end
  end
end
