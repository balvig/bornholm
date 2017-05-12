# CP-8 Cookpad Bot (test)

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

<img src="https://cloud.githubusercontent.com/assets/104138/13375017/617ffdd0-dd95-11e5-9b59-87605963b351.png" width="40%"/>

## Usage

- Opening a PR with "[WIP]" in title adds `WIP` label
- Opening PR with "[Delivers #....]" in title moves card to `finished` row on Trello
- Closing PR with "[Delivers #....]" in title moves card to `merged` row on Trello
- CP-8 will comment on issues with no activity for more than 5 weeks
