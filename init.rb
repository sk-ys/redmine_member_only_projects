$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/lib')
require 'member_only_projects/patches/project_patch'
require 'member_only_projects/patches/user_patch'
require 'member_only_projects/user_flag'

Redmine::Plugin.register :redmine_member_only_projects do
  name        'Redmine Member Only Projects'
  author      'sk-ys'
  description 'Users flagged via a user custom field can only see projects they are members of'
  version     '0.1.0'
  requires_redmine version_or_higher: '6.0.0'

  settings default: { 'user_cf_id' => nil }, partial: 'settings/member_only_projects'
end
