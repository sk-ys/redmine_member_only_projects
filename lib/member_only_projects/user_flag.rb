module MemberOnlyProjects
  module UserFlag
    module_function

    # Check if the user has the member-only flag enabled
    def member_only?(user)
      return false if user.nil? || user.anonymous? || user.admin?

      cf_id = Setting.plugin_redmine_member_only_projects['user_cf_id'].to_i
      return false if cf_id <= 0

      cf = CustomField.find_by(id: cf_id)
      return false unless cf && cf.type == 'UserCustomField'

      val = user.custom_value_for(cf)
      (val && val.value.to_s == '1')
    rescue => e
      Rails.logger.warn("[MemberOnlyProjects] flag check failed: #{e}")
      false
    end
  end
end
