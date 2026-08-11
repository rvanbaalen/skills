# Hermes Tweet

Claude Code guidance for the [Hermes Tweet](https://github.com/Xquik-dev/hermes-tweet) Hermes Agent plugin.

Hermes Tweet adds X/Twitter search, account reads, monitoring, and approval-gated account actions to Hermes Agent through Xquik. This marketplace package gives Claude Code users a compact operating guide for installing the Hermes plugin, selecting the right tool, and keeping action routes gated.

## Install

```bash
/plugin install hermes-tweet@rvanbaalen
```

## Use

Invoke the skill when a Hermes Agent workflow needs X/Twitter data or controlled account actions:

```text
/hermes-tweet:hermes-tweet
```

The skill keeps the workflow read-first:

- Use `tweet_explore` to find catalog-listed endpoints.
- Use `tweet_read` for read-only endpoints after `XQUIK_API_KEY` is configured in the Hermes runtime.
- Use `tweet_action` only for approved writes, private reads, monitors, webhooks, extraction jobs, media operations, or giveaway draws.
- Keep `HERMES_TWEET_ENABLE_ACTIONS=false` unless the current session intentionally allows account-changing actions.

## Hermes Plugin

Install Hermes Tweet in Hermes Agent:

```bash
hermes plugins install Xquik-dev/hermes-tweet --enable
```

Hermes stores runtime configuration in the Hermes environment. Do not paste API keys, cookies, passwords, or TOTP secrets into Claude Code chat, issue bodies, PR comments, logs, or tool input.

## References

- [Hermes Tweet repository](https://github.com/Xquik-dev/hermes-tweet)
- [Hermes Tweet PyPI package](https://pypi.org/project/hermes-tweet/)
- [Hermes Agent](https://github.com/NousResearch/hermes-agent)
