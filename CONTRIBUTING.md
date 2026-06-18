# Contributing

Thanks for wanting to add an example. Everything lives in this one repo — send
yours as a pull request.

1. **Fork** the repo and branch.
2. **Add one directory** named after your example, with a single script inside
   (e.g. `disk-space/disk-space.sh`). One example per directory.
3. **Open the script with a docstring header**: what it does, which widget type
   + channel to add, setup, and usage — copy the shape from any existing one.
4. **Target a default channel** (`text_1`, `line_chart_1`, `state_1`, `mini_1`,
   …), never a custom name. A user shouldn't have to name a widget to match.
5. **Add a row** to the examples table in the [README](README.md).
6. **Open the PR.**

By submitting, you agree to license your contribution under this repo's
[MIT license](LICENSE).
