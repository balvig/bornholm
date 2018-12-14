# CP-8 Cookpad Bot

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

<img src="https://cloud.githubusercontent.com/assets/104138/13375017/617ffdd0-dd95-11e5-9b59-87605963b351.png" width="40%"/>

## Purpose

- Keep trackers clean by cleaning out stale pull requests/issues
- Help reviewers focus by tagging WIP pull requests
- Tighten review loop by notifying when PRs need immediate attention
- Move issues between projects

## Usage

CP-8 can:

- Close stale issues with no activity
- Add a `WIP` label to PRs with "[WIP]" in title
- Notify in specified Slack channel when:
  - a new (non-WIP) PR is opened
  - a WIP PR is "un-WIPped"
  - a `:recycle:` comment is posted
  - a PR is approved/has changes requested
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
```

## User Mapping

Your Github username needs to be mapped to your Slack ID so cp8 can send you slack notifications:

- Copy your Slack ID from your account settings
- Submit a PR to this repo to add `[github_name]:[slack_id]` to `/lib/user_mappings.yml`. See, for example, [this PR](https://github.com/cookpad/cp8/pull/68))

## CLI

CP8 has a [CLI counterpart](https://github.com/cookpad/cp8_cli), that while not required, provides some extra convenience for GitHub-driven projects in addition to what the bot offers.
