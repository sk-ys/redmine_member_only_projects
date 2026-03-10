module MemberOnlyProjects
  module UserFlag
    module_function

    # Check if the user has the member-only flag enabled via UserPreference
    def member_only?(user)
      return false if user.nil? || user.anonymous? || user.admin?

      user.pref[:member_only_projects].to_s == '1'
    rescue => e
      Rails.logger.warn("[MemberOnlyProjects] flag check failed: #{e}")
      false
    end
  end
end
