module MemberOnlyProjects
  module Patches
    module UserPreferencePatch
      def self.included(base)
        base.safe_attributes('member_only_projects')
      end

      # Default is disabled when no preference exists.
      # Reads explicitly from the serialized `others` hash to avoid being
      # mistaken for an ActiveRecord column accessor.
      def member_only_projects
        h = read_attribute(:others) || {}
        ActiveModel::Type::Boolean.new.cast(h[:member_only_projects]) ? '1' : '0'
      end

      # Writes to the serialized `others` hash (duplicates to ensure AR dirty
      # tracking detects the change).
      def member_only_projects=(value)
        h = (read_attribute(:others) || {}).dup
        h[:member_only_projects] = ActiveModel::Type::Boolean.new.cast(value) ? '1' : '0'
        write_attribute(:others, h)
      end
    end
  end
end

unless UserPreference.included_modules.include?(MemberOnlyProjects::Patches::UserPreferencePatch)
  UserPreference.include MemberOnlyProjects::Patches::UserPreferencePatch
end
