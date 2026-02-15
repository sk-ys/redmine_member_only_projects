# Patch User#allowed_to? to restrict permissions to members only
module MemberOnlyProjects
  module Patches
    module UserPatch
      def allowed_to?(action, context, options = {}, &block)
        if self != User.anonymous && MemberOnlyProjects::UserFlag.member_only?(self)
          if Setting.login_required?
            # login_required=true: restrict to member projects only
            if context.is_a?(Project)
              # Only allow if user is a member of the project
              return false unless member_of?(context)

              # If user is a member, check normal permissions
              return super
            elsif context.is_a?(Array)
              # Filter to only projects where user is a member
              member_projects = context.select { |p| p.is_a?(Project) && member_of?(p) }
              return false if member_projects.empty?

              # Check permissions on member projects only
              return super(action, member_projects, options, &block)
            end
          else
            # login_required=false: follow anonymous permissions
            # Anonymous users can see public projects, so we check what they can do for issues
            anonymous_can = User.anonymous.allowed_to?(action, context, options, &block)

            # For projects, return false if anonymous cannot do it (unless we're a member)
            if context.is_a?(Project)
              return anonymous_can unless member_of?(context)

              # If we're a member, check normal permissions
              return super
            elsif context.is_a?(Array)
              # For arrays, filter based on anonymous permissions too
              accessible_projects = context.select do |p|
                p.is_a?(Project) && (User.anonymous.allowed_to?(action, p, options, &block) || member_of?(p))
              end
              return false if accessible_projects.empty?

              return super(action, accessible_projects, options, &block)
            end
          end
        end

        super
      end
    end
  end
end

User.prepend MemberOnlyProjects::Patches::UserPatch
