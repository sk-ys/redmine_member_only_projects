module MemberOnlyProjects
  module UserFlag
    module_function

    # Check if the user has the member-only flag enabled
    def member_only?(user)
      return false if user.nil? || user.anonymous? || user.admin?

      group_id = Setting.plugin_redmine_member_only_projects['group_id'].to_i
      return false if group_id <= 0

      user.groups.exists?(id: group_id)
    rescue => e
      Rails.logger.warn("[MemberOnlyProjects] flag check failed: #{e}")
      false
    end
  end
end
