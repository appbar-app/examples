# CLI

`appbar` ships with the app — install it from **AppBar → Settings**. It writes
to the same socket as the [raw JSON protocol](SOCKETJSON.md); the commands below
are just a convenient wrapper.

```
appbar <subcommand>      # emit | clear | widget
appbar -h                # help; `appbar <sub> -h` for a subcommand
```

## appbar widget — push to a custom widget

```
appbar widget --channel <ch> [--value <n>] [--text <s>] [--active <bool>] \
              [--input <bytes/s>] [--output <bytes/s>] [--label <s>] [--icon <s>]
```

- `--channel` (**required**) — e.g. `text_1` (see [WIDGETS.md](WIDGETS.md)).
- `--value` — number; mini/tachometer read it as 0–1, charts append it.
- `--text`, `--label`, `--icon` — `--icon` is an SF Symbol name.
- `--active` — `true`/`false` for State widgets.
- `--input`, `--output` — bytes/s for Network/Speed widgets.

```sh
appbar widget --channel text_1 --text "hello" --icon hand.wave
appbar widget --channel mini_1 --value 0.42 --label cpu
appbar widget --channel state_1 --active true --icon hammer.circle
```

Pie `segments` and multi-point chart `values` arrays have no CLI flag — write
them to the [socket](SOCKETJSON.md) instead.

## appbar emit — emit an event

```
appbar emit <event-type> [--title <s>] [--severity info|warning|critical] \
            [--host <s>] [--project <s>]
```

Types prefixed `context`/`threshold` persist; everything else is a transient
alert (default severity `info`).

```sh
appbar emit task.failed --title "build failed" --severity warning
appbar emit context.changed --title prod
```

## appbar clear — clear events

```
appbar clear <event-type>      # or: appbar clear all
```

```sh
appbar clear task.failed
appbar clear all
```

(`install-symlink` / `uninstall-symlink` are internal — run by the Settings
install button, not by hand.)
