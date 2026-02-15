# frozen_string_literal: true

require_relative '../test_helper'

class MemberOnlyProjectsTest < ActiveSupport::TestCase
  fixtures :users, :projects, :members, :roles, :member_roles, :enabled_modules

  def setup
    # Save original setting
    @original_login_required = Setting.login_required
    @original_plugin_setting = Setting.plugin_redmine_member_only_projects

    # Use 'someone' user who is not a member of any project (from fixtures)
    @user = User.find_by(login: 'someone') # User who does not belong to any project
    @admin = User.find_by(login: 'admin') # Admin user
    @anonymous = User.anonymous
    @public_project = Project.find_by(is_public: true)
    @private_project = Project.find_by(is_public: false)

    # Create a user custom field for member_only flag
    @custom_field = UserCustomField.create!(
      name: 'member_only',
      field_format: 'bool',
      is_required: false,
      visible: true
    )

    # Configure the plugin to use this custom field
    Setting.plugin_redmine_member_only_projects = { 'user_cf_id' => @custom_field.id.to_s }

    # Flag the user as member_only via the custom field
    @user.custom_field_values = { @custom_field.id => '1' }
    @user.save!

    # Set login_required to true for all tests
    Setting.login_required = '1'
  end

  def teardown
    # Clean up and restore original setting
    @custom_field&.destroy
    Setting.login_required = @original_login_required
    Setting.plugin_redmine_member_only_projects = @original_plugin_setting
  end

  test 'member_only user should not see public project unless member (login_required=true)' do
    assert @public_project.is_public?, "Project should be public"
    assert_not @user.member_of?(@public_project), "User should not be member of public project"

    # Member_only users should not see non-member projects
    result = @user.allowed_to?(:view_project, @public_project)
    assert_not result, "Member_only user should not be allowed to view non-member public project"
  end

  test 'member_only user should not see public project unless member (login_required=false)' do
    Setting.login_required = '0'

    assert @public_project.is_public?, "Project should be public"
    assert_not @user.member_of?(@public_project), "User should not be member of public project"

    # When login_required=false, member_only users see the same projects as anonymous users (all public projects)
    result = @user.allowed_to?(:view_project, @public_project)
    assert result, "Member_only user should see public project when login_required=false (same as anonymous)"
  end

  test 'member_only user should see project if member' do
    project = @public_project

    role = Role.find_by(name: 'Manager') || Role.first
    Member.create!(user: @user, project: project, role_ids: [role.id])
    @user.reload

    assert @user.member_of?(project), "User should be member of project"
    assert @user.allowed_to?(:view_project, project), "Member_only user should be allowed to view project when they are a member"
  end

  test 'admin should see all projects' do
    assert @admin.allowed_to?(:view_project, @public_project)
    assert @admin.allowed_to?(:view_project, @private_project)
  end

  test 'anonymous user is not affected by member_only flag' do
    # Set login_required to false for this specific test
    Setting.login_required = '0'
    # Anonymous users should see public projects regardless of the plugin
    # (the plugin only affects non-anonymous, non-admin users with the flag set)
    assert @anonymous.allowed_to?(:view_project, @public_project)
  end

  test 'member_only user can see issues in member projects when login_required=on' do
    Setting.login_required = '1'

    # Create a member relationship
    project = @public_project
    role = Role.find_by(name: 'Manager') || Role.first
    Member.create!(user: @user, project: project, role_ids: [role.id])
    @user.reload

    # User should be able to see issues in member project
    assert @user.allowed_to?(:view_issues, project)
  end

  test 'member_only user can see issues in public projects when login_required=off' do
    Setting.login_required = '0'

    # User is not a member of the public project
    assert_not @user.member_of?(@public_project)

    # When login_required=false, member_only users should see issues same as anonymous users
    # Get what anonymous users can see
    anonymous_can_view = @anonymous.allowed_to?(:view_issues, @public_project)

    # member_only users should have the same permission as anonymous users
    member_only_can_view = @user.allowed_to?(:view_issues, @public_project)

    # The result should be the same as anonymous user
    assert_equal anonymous_can_view, member_only_can_view,
      "Member_only user should have same view_issues permission as anonymous when login_required=false"
  end

  test 'member_only user restricted by anonymous permissions when login_required=off' do
    Setting.login_required = '0'

    # This test verifies that if anonymous users cannot view issues,
    # then member_only users also cannot view issues in non-member projects
    anonymous_result = @anonymous.allowed_to?(:view_issues, @public_project)
    member_only_result = @user.allowed_to?(:view_issues, @public_project)

    # When anonymous cannot view, member_only should also not view
    # when anonymous can view, member_only should also be able to view
    assert_equal anonymous_result, member_only_result,
      "Plugin should not add extra restrictions; member_only should follow anonymous permissions"
  end

  test 'member_only user cannot see issues when anonymous role lacks permission when login_required=off' do
    Setting.login_required = '0'

    # Get the anonymous role
    anonymous_role = Role.find_by(builtin: Role::BUILTIN_ANONYMOUS)
    skip 'Anonymous role not found' unless anonymous_role

    # Store original permissions
    original_perms = anonymous_role.permissions.dup

    begin
      # Remove view_issues permission from anonymous role
      anonymous_role.permissions = anonymous_role.permissions - [:view_issues]
      anonymous_role.save!

      # Reload objects to clear cached permissions
      @anonymous.reload
      @user.reload

      # Verify anonymous cannot view issues now
      assert_not @anonymous.allowed_to?(:view_issues, @public_project),
        "Anonymous should not be able to view issues after removing permission"

      # Verify member_only user also cannot view issues (follows anonymous)
      assert_not @user.allowed_to?(:view_issues, @public_project),
        "Member_only user should follow anonymous permissions and not see issues"
    ensure
      # Restore original permissions
      anonymous_role.permissions = original_perms
      anonymous_role.save!
      @anonymous.reload
      @user.reload
    end
  end

  test 'member_only user sees issues when anonymous role has permission when login_required=off' do
    Setting.login_required = '0'

    # Get the anonymous role
    anonymous_role = Role.find_by(builtin: Role::BUILTIN_ANONYMOUS)
    skip 'Anonymous role not found' unless anonymous_role

    # Store original permissions
    original_perms = anonymous_role.permissions.dup

    begin
      # Ensure view_issues permission exists in anonymous role
      view_issues_perm = anonymous_role.permissions.include?(:view_issues)

      unless view_issues_perm
        # Add view_issues permission
        anonymous_role.permissions = anonymous_role.permissions + [:view_issues]
        anonymous_role.save!
      end

      # Reload objects to clear cached permissions
      @anonymous.reload
      @user.reload

      # Verify anonymous can view issues
      assert @anonymous.allowed_to?(:view_issues, @public_project),
        "Anonymous should be able to view issues with permission"

      # Verify member_only user also can view issues (follows anonymous)
      assert @user.allowed_to?(:view_issues, @public_project),
        "Member_only user should see issues when anonymous has permission"
    ensure
      # Restore original permissions if we changed them
      unless view_issues_perm
        anonymous_role.permissions = original_perms
        anonymous_role.save!
        @anonymous.reload
        @user.reload
      end
    end
  end
end
