# Socket protocol

AppBar listens on `/tmp/appbar.sock`. Write one JSON object per line; AppBar
applies the frame and closes. The `appbar` CLI is just a wrapper around this.

```sh
printf '%s\n' '{"type":"widget.update","widget":{"channel":"text_1","text":"hi"}}' \
  | nc -U /tmp/appbar.sock
```

## Envelope

- `type` (string, **required**) — `widget.update`, `clear:<type>`, or an event name.
- `widget` (object) — for `widget.update`; the only required field is `channel`.
- `title`, `severity` (`info`|`warning`|`critical`), `context` (string map),
  `timestamp` (ISO8601), `ttl` (seconds) — for event types.

Types prefixed `context`/`threshold` persist; everything else is a transient alert.

## Widgets

A Custom widget auto-names to `<type>_<n>` (the first of each type is `_1`).
`icon` is an SF Symbol name; `label` overrides the caption. See
[WIDGETS.md](WIDGETS.md) for what each type shows; the JSON for each follows.

### Text — `text_1`

```json
{"type":"widget.update","widget":{"channel":"text_1","text":"hello","icon":"hand.wave"}}
```

### Mini — `mini_1`

`value` is a 0–1 fraction (shown as a percentage).

```json
{"type":"widget.update","widget":{"channel":"mini_1","value":0.42,"label":"cpu"}}
```

### Tachometer — `tachometer_1`

`value` is a 0–1 fraction.

```json
{"type":"widget.update","widget":{"channel":"tachometer_1","value":0.75}}
```

### State — `state_1`

```json
{"type":"widget.update","widget":{"channel":"state_1","active":true,"icon":"hammer.circle"}}
```

### Line chart — `line_chart_1`

Push `value` to append a point, or `values` to set the whole history.

```json
{"type":"widget.update","widget":{"channel":"line_chart_1","value":18}}
```

### Bar chart — `bar_chart_1`

```json
{"type":"widget.update","widget":{"channel":"bar_chart_1","values":[0.2,0.5,0.9,0.4]}}
```

### Pie chart — `pie_chart_1`

Each segment `value` is a fraction of the circle (slices sum to ~1). `color` is
a name: `red` `orange` `yellow` `green` `blue` `purple` `pink` `gray` (default blue).

```json
{"type":"widget.update","widget":{"channel":"pie_chart_1","segments":[{"value":0.6,"color":"green","label":"used"},{"value":0.4,"color":"gray","label":"free"}]}}
```

### Network / Speed — `network_chart_1`, `speed_1`

`input`/`output` are bytes per second (`speed_bits_1` shows bits).

```json
{"type":"widget.update","widget":{"channel":"network_chart_1","input":1048576,"output":262144}}
```

## Events

```json
{"type":"task.failed","title":"build failed","severity":"warning"}
{"type":"clear:task.failed"}
```

Limits: frame 64 KB · title 1024 · values 4000 · segments 500.
