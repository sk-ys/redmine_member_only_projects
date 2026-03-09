module MemberOnlyProjects
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_users_form_preferences,
              partial: 'member_only_projects/user_preference_fields'
  end
end
