# Redmine Member Only Projects

## Overview

This plugin allows you to configure specific users to view only projects where they are members. Users with this setting enabled will not be able to see public projects where they are not members. You can use this plugin if you want to hide public projects from specific users.

**⚠️Caution:** This plugin customizes Redmine's permission logic. If misconfigured or malfunctioning, it may cause unintended information disclosure. Please use with caution and test thoroughly before deploying in production environments.

日本語版README: [README_ja.md](README_ja.md)

## Features

- **Member-only visibility**: Restrict selected users to see only projects where they are members
- **Flexible configuration**: You can enable or disable this restriction for each user via a user preference
- **No DB migration**: Uses Redmine's built-in UserPreference, so no plugin-specific tables are created

## Installation

1. Clone or download the plugin to your Redmine plugins directory:

   ```
   cd /path/to/redmine/plugins
   git clone https://github.com/sk-ys/redmine_member_only_projects.git
   ```

2. Restart Redmine

## Configuration

### How the plugin works

#### When "Authentication required" is ON (`login_required=true`):

- member_only users see **only projects they are members of**
- Public projects are hidden unless the user is a member

#### When "Authentication required" is OFF (`login_required=false`):

- member_only users see **projects where they are members** as well as **projects that anonymous users can access**
- Issue visibility follows the same logic: visible if user is a member OR if anonymous users can view issues
- This ensures that restricting anonymous user permissions also restricts member_only users appropriately

### Setup Steps

#### Step 1: Enable the "Member only projects" preference for a user

Go to **Administration → Users**, open a user's edit page, and check **"Member only projects"** in the Preferences section.

![](docs/images/user_settings.png)

That's all — no custom fields or plugin-level settings are required.

## Requirements

- Redmine 6+

## License

This plugin is released under the GPLv2 License.
