# The Log tab

**Settings → Log** records every push, so you can see exactly what reached
AppBar and where it went. Filter by **OK**, **No Target**, or **Errors**.

Everything arrives over the same Unix socket, so both the `appbar` CLI and a
direct socket write (like [`hello-socket/`](../hello-socket/hello-socket.sh))
show up tagged **Sock** — the log can't tell them apart, because the CLI is just
writing to that socket for you.

A plain text push (`hello-world` → `text_1`):

![Text push in the Log](../screenshots/log-text.png)

A text push carrying a label + icon (`weather` → `text_1`):

![Text push with label and icon in the Log](../screenshots/log-text-weather.png)

A line-chart push (`ping-latency` → `line_chart_1`):

![Line chart pushes in the Log](../screenshots/log-line-chart.png)

A state widget plus its event (`run-status` → `state_1`):

![State + event in the Log](../screenshots/log-state.png)

Pushed to a channel with no widget — accepted, but flagged **No Target** (this
is why nothing shows up if you forgot to add the widget):

![No Target in the Log](../screenshots/log-no-target.png)
