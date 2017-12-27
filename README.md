# CP-8 Cookpad Bot (test)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

<img src="https://cloud.githubusercontent.com/assets/104138/13375017/617ffdd0-dd95-11e5-9b59-87605963b351.png" width="40%"/>

## Setup

- Invite GitHub bot user to GitHub repo
- Add `/payload` webhook to GitHub repo

## Usage

CP-8 will:

- Add a `WIP` label to PRs with "[WIP]" in title
- Notify in Slack `#reviews` channel when a `:recycle:` comment is posted
- Close issues with no activity for more than 4 weeks

## Options

```
/payload?config[stale_issue_weeks]=6 # Set stale issue cutoff to 6 weeks
```
