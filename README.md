# CP-8 Cookpad Bot

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

<img src="https://cloud.githubusercontent.com/assets/104138/13375017/617ffdd0-dd95-11e5-9b59-87605963b351.png" width="40%"/>

## Purpose

- Tighten review loop by notifying when PRs need immediate attention
- Keep trackers clean by cleaning out stale pull requests/issues
- Move issues between projects

## Usage

CP-8 can:

- Close stale issues with no activity
- Notify in specified Slack channel when:
  - a PR is published
  - a `:recycle:` comment is posted
  - a PR is reviewed
  - a PR is blocking other PRs signified by having `[Blocker]` in the title
- Automatically add new issues to projects

## Setup

- Install [GitHub app](https://github.com/apps/cp8-cookpad-bot)

## Configuration

Add `.cp8.yml` file to root of project, and turn on features by configuring them:

```yml
stale_issue_weeks: 4 # Set stale issue cutoff to 4 weeks
review_channel: reviews # Send review requests/updates to specified Slack channel
project_column_id: 49 # Automatically add new issues to a project column
mention_threshold: 100 # Only PRs with less additions than this limit will trigger mentions (default 100)
```

## User Mapping

Your GitHub username needs to be mapped to your Slack ID in order for CP8 to mention you:

- Copy your Slack ID from your account settings
  - In the Slack desktop application, click your name in the top left then click 'Profile & account'. On the Profile panel that opens, click the vertical ellipses button which should be below your profile photo to the right of the 'Edit Profile' button, then select 'Copy Member ID'.
- Submit a PR to this repo to add `[github_name]: [slack_id]` to `/lib/user_mappings.yml`. See, for example, [this PR](https://github.com/cookpad/cp8/pull/68))

## CLI

CP8 has a [CLI counterpart](https://github.com/cookpad/cp8_cli), that while not required, provides some extra convenience for GitHub-driven projects in addition to what the bot offers.
