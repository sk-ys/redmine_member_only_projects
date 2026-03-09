$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/lib')
require 'member_only_projects/patches/project_patch'
require 'member_only_projects/patches/user_patch'
require 'member_only_projects/user_flag'
require 'member_only_projects/hooks'

Redmine::Plugin.register :redmine_member_only_projects do
  name        'Redmine Member Only Projects'
  author      'sk-ys'
  description 'Users flagged via user preferences can only see projects they are members of'
  version     '0.1.0'
  requires_redmine version_or_higher: '6.0.0'
end

# Allow the member_only_projects preference to be set via the standard pref[] form params
UserPreference.safe_attributes 'member_only_projects'
