$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/lib')
require 'member_only_projects/patches/project_patch'
require 'member_only_projects/patches/user_patch'
require 'member_only_projects/user_flag'

Redmine::Plugin.register :redmine_member_only_projects do
  name        'Redmine Member Only Projects'
  author      'sk-ys'
  description 'Users in a designated group can only see projects they are members of'
  version     '0.2.0'
  requires_redmine version_or_higher: '6.0.0'

  settings default: { 'group_id' => nil }, partial: 'settings/member_only_projects'
end
