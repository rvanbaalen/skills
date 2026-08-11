---
name: hermes-tweet
description: Use Hermes Tweet when a Hermes Agent workflow needs X/Twitter search, account reads, monitoring, or approval-gated account actions through Xquik.
argument-hint: "[task]"
---

# Hermes Tweet

Use this skill when the user wants to install, configure, troubleshoot, or operate the Hermes Tweet plugin for Hermes Agent.

Hermes Tweet is a native Hermes Agent plugin for X/Twitter workflows through Xquik. It exposes a read-first flow with `tweet_explore`, `tweet_read`, and approval-gated `tweet_action`.

## Use When

- The user needs X/Twitter search, timelines, user profiles, mentions, trends, monitors, extraction jobs, media, giveaway draws, or controlled posting from Hermes Agent.
- The user asks how to install or enable Hermes Tweet in Hermes Agent.
- The user needs to decide whether an X/Twitter task should use `tweet_read` or `tweet_action`.
- The user is troubleshooting missing Hermes Tweet tools after installation.

## Tool Choice

1. Start with `tweet_explore` to find the catalog-listed endpoint.
2. Use `tweet_read` only for read-only endpoints after `XQUIK_API_KEY` is configured in the Hermes runtime.
3. Use `tweet_action` only for writes, private reads, monitors, webhooks, extraction jobs, media operations, or giveaway draws after the user approves the endpoint and payload.

Do not guess endpoint paths. Do not create direct HTTP fallbacks. Use only catalog-listed `/api/v1/...` routes returned by Hermes Tweet.

## Install

Install and enable the Hermes plugin:

```bash
hermes plugins install Xquik-dev/hermes-tweet --enable
```

If the plugin is installed but disabled, run:

```bash
hermes plugins enable hermes-tweet
```

Verify the runtime surface:

```bash
hermes plugins list
hermes tools list
```

## Configuration

Set configuration where the Hermes runtime executes:

- `XQUIK_API_KEY` enables authenticated reads.
- `HERMES_TWEET_ENABLE_ACTIONS=true` enables account-changing actions.
- Keep actions disabled by default for unattended, scheduled, or read-only workflows.

Never ask for or echo secret values. Ask the user to set them in the Hermes runtime environment instead.

## Safety Rules

- Never request API keys, cookies, passwords, or TOTP secrets in chat.
- Never put credentials in tool arguments, examples, issue bodies, PR comments, logs, or generated files.
- Keep `tweet_action` disabled unless the current task has an explicit approval step.
- Summarize side effects before posting, deleting, following, sending DMs, changing profiles, creating monitors, configuring webhooks, running extraction jobs, uploading media, or drawing giveaways.
- Reject account connection, re-authentication, API key, billing, credit top-up, and support-ticket endpoints.

## Remote Gateway Notes

For Hermes Desktop or remote gateway profiles, install and configure Hermes Tweet on the remote Hermes host. The desktop chat surface does not automatically provide runtime environment variables to the host where plugin tools execute.

## References

- Hermes Tweet: https://github.com/Xquik-dev/hermes-tweet
- PyPI package: https://pypi.org/project/hermes-tweet/
- Hermes Agent: https://github.com/NousResearch/hermes-agent
