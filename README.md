# CP-8 Cookpad Bot (test branch)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

<img src="https://cloud.githubusercontent.com/assets/104138/13375017/617ffdd0-dd95-11e5-9b59-87605963b351.png" width="40%"/>

## Purpose

- Keep trackers clean by cleaning out stale pull requests/issues
- Help reviewers focus by tagging WIP pull requests
- Tighten review loop by notifying when PRs need immediate attention

## Setup

- Invite GitHub bot user to GitHub repo
- Add `/payload` webhook to GitHub repo

## Usage

CP-8 will:

- Close issues with no activity for more than 4 weeks
- Add a `WIP` label to PRs with "[WIP]" in title
- Notify in specified Slack channel when:
  - a new (non-WIP) PR is opened
  - a WIP PR is "un-WIPped"
  - a `:recycle:` comment is posted
  - a PR is approved/has changes requested

## Options

```ruby
/payload?config[stale_issue_weeks]=6 # Set stale issue cutoff to 6 weeks
/payload?config[review_channel]=reviews # Send review requests/updates to specified Slack channel
```
