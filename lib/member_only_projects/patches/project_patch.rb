# Patch Project.allowed_to_condition to restrict projects to members only
module MemberOnlyProjects
  module Patches
    module ProjectPatch
      def self.prepended(base)
        class << base
          prepend ClassMethods
        end
      end

      module ClassMethods
        def allowed_to_condition(user, permission, options = {}, &)
          if MemberOnlyProjects::UserFlag.member_only?(user)
            merged = options ? options.merge(member: true) : { member: true }

            # Get the condition for member projects
            member_condition = super(user, permission, merged, &)

            if Setting.login_required?
              # login_required=true: restrict to member projects only
              return member_condition
            else
              # login_required=false: show member projects OR projects where anonymous can view
              # Get the condition for anonymous access
              anon_condition = super(User.anonymous, permission, options, &)

              # Combine with OR logic: (member condition) OR (anonymous condition)
              # Since we can't easily OR conditions in Rails, we'll use a simpler approach:
              # Include projects where user is a member, plus projects where anonymous can view
              # This is handled by letting the normal permission check work, but filtering to:
              # - All member projects for this user
              # - All projects where anonymous has permission

              if member_condition.is_a?(String) && anon_condition.is_a?(String)
                # Both are SQL conditions, combine with OR
                return "(#{member_condition}) OR (#{anon_condition})"
              end

              # Fallback: just use member condition (union with anonymous condition handled elsewhere)
              return member_condition
            end
          end
          super
        end
      end
    end
  end
end

Project.prepend MemberOnlyProjects::Patches::ProjectPatch
