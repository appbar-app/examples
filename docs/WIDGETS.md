# Widget types

AppBar's **Custom** widgets — the ones these examples target. Add one in
**Settings → Widgets**; the first of each type auto-names to `<type>_1`
(`text_1`, `line_chart_1`, …). Drive them with `appbar widget` or by writing to
the [socket](SOCKETJSON.md).

| Widget | Channel | Shows | Driven by |
|---|---|---|---|
| **Text** | `text_1` | a string + icon | `text`, `icon` |
| **Mini** | `mini_1` | a compact percentage + icon | `value` (0–1) |
| **Tachometer** | `tachometer_1` | a dial gauge | `value` (0–1) |
| **State** | `state_1` | an on/off indicator + icon | `active` |
| **Line chart** | `line_chart_1` | a value's recent history as a sparkline | `value` (appends a point) or `values` |
| **Bar chart** | `bar_chart_1` | a row of bars | `values` |
| **Pie chart** | `pie_chart_1` | proportional slices | `segments` (each `value` a 0–1 fraction) |
| **Network** | `network_chart_1` | up/down throughput over time | `input`, `output` (bytes/s) |
| **Speed** | `speed_1` (`speed_bits_1` for bits) | the current up/down rate | `input`, `output` (bytes/s) |

Notes:

- **`value` is a 0–1 fraction** for Mini and Tachometer (shown as a percentage).
  A raw number like a temperature does not belong here — use **Text**.
- **Pie** slices should sum to ~1; segment `color` is a name (`red` `orange`
  `yellow` `green` `blue` `purple` `pink` `gray`).
- `icon` is any SF Symbol name.

Full JSON for each: [SOCKETJSON.md](SOCKETJSON.md).

## Adding a widget

Open **Settings → Widgets**:

![The Widgets tab](../screenshots/widgets-tab.png)

Scroll to the **Custom** section and drag a **Text**, **Line Chart**, or
**State** widget onto a bar:

![The Custom widget section](../screenshots/custom-widgets.png)

Once added, each shows its auto-assigned channel name — `text_1`, `state_1`,
`line_chart_1` — the names the examples target:

![Custom widgets added to the bars](../screenshots/widgets-added.png)

