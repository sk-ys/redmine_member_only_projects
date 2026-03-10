module MemberOnlyProjects
  module Patches
    module UserPreferencePatch
      def self.included(base)
        base.safe_attributes('member_only_projects')
      end

      # Default is disabled when no preference exists.
      def member_only_projects
        ActiveModel::Type::Boolean.new.cast(self[:member_only_projects]) ? '1' : '0'
      end

      def member_only_projects=(value)
        self[:member_only_projects] = ActiveModel::Type::Boolean.new.cast(value) ? '1' : '0'
      end
    end
  end
end

unless UserPreference.included_modules.include?(MemberOnlyProjects::Patches::UserPreferencePatch)
  UserPreference.include MemberOnlyProjects::Patches::UserPreferencePatch
end
