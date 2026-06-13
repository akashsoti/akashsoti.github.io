# CSS Override Architecture

`tokens.css` is the only place to define design tokens: font families, type scale, theme colors, surfaces, borders, shadows, and selection colors.

Self-hosted font-face declarations live in `tokens.css` before the tokens that consume them.

`theme.css` and `typography.css` consume tokens. They should not define new `--type-*`, `--font-family-*`, `--bg-*`, `--fg-*`, or shadow tokens.

`style.css` is the legacy compiled base layer. Keep current visual design work in this `overrides` folder unless the legacy layout system itself needs to change.

When adding a new component stylesheet, load it after `tokens.css` and use existing tokens before adding a new one.
