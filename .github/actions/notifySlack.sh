#!/bin/sh -l

set -e

actionPath="https://www.github.com/$GITHUB_REPOSITORY/actions"

title="$1"
status="$2"
branch="$3"

fallbackMessage=$message

template='{
    text: $fallbackMsg,
    blocks: [
        {
            type: "section",
            text: {
                type: "mrkdwn",
                text: $title
            },
            accessory: {
                type: "button",
                text: {
                    type: "plain_text",
                    emoji: true,
                    text: "View Results"
                },
                url: $path
            }
        },
        {
			type: "context",
			elements: [
				{
					type: "mrkdwn",
					text: $status
				},
                {
					type: "mrkdwn",
					text: $branch
				}
			]
		}
    ]
}'

json=$(jq -n \
    --arg title "${title}" \
    --arg fallbackMsg "${message}" \
    --arg path "$actionPath" \
    --arg branch "*Branch:* $branch" \
    --arg status "*Status*: $status" \
    "$template")

curl -X POST -H 'Content-type: application/json' -d "$json" "$SLACK_WEBHOOK"
