# AGENTS.md

## What this is

Pure-Lua Neovim plugin. No build step, no compile, no bundle. "Installing" means pointing a plugin manager at this directory.

## Testing

Framework: `busted` + `nlua` (Neovim as the Lua interpreter). Tests live in `spec/`.

```bash
task test                              # run all specs
task test-file -- spec/url_spec.lua    # run a single file
```

Manual equivalent without `task`:
```bash
eval "$(luarocks --lua-version 5.1 path)" && busted --lua ~/.luarocks/bin/nlua spec/
```

**One-time setup** (if `nlua`/`busted` are not yet installed for Lua 5.1):
```bash
luarocks --local --lua-version 5.1 install nlua
luarocks --local --lua-version 5.1 install busted
```

Dependencies must be installed for **Lua 5.1** (LuaJIT), not Lua 5.5. Using the wrong version causes `.so` load failures under `nlua`.

`Taskfile.yaml` hard-codes `NLUA: ~/.luarocks/bin/nlua`. Update that var if `nlua` lives elsewhere.

### Test coverage

| Spec file | Module | Notes |
|---|---|---|
| `spec/url_spec.lua` | `lib/url.lua` | Pure Lua, no mocking |
| `spec/toc_spec.lua` | `lib/toc.lua` | Synthetic header tables, no mocking |
| `spec/cursor_spec.lua` | `lib/cursor.lua` | Stubs `vim.api`/`vim.fn` via `luassert.stub` |
| `spec/tree_spec.lua` | `lib/tree.lua` | Real scratch buffers with `filetype=markdown` |

Each spec file sets `package.path` itself — no `minimal_init.lua` or plenary required.

## Entry point (no build step)

`lua/nvim-md-toc/init.lua` — loaded by `require("nvim-md-toc")`. Two public functions: `setup(opts)` and `refresh_toc(level)`.

## Neovim version requirement

Requires Neovim 0.9+ for `vim.treesitter.query.parse(...)`. The older `vim.treesitter.parse_query` form must not be used.

## Load-bearing typo

The config key is `themeatic_break` (not `thematic_break`). This spelling appears identically in `default_options`, `M.setup`, and `M.refresh_toc` in `init.lua`. Fixing the typo would be a breaking API change. Do not silently "correct" it.

## Thematic break detection quirk

`tree.lua` uses a Tree-sitter `(thematic_break)` query to find the TOC separator — not a literal string match on `____`. This means any valid Markdown HR (`---`, `***`, `___`, `____`) in the file will be treated as the TOC boundary, and all content above it will be deleted on refresh. This is a known design limitation.

## Default register side-effect

`cursor.lua` saves/restores cursor position by writing to a Vim register (default `"v"`). This clobbers whatever the user stored in that register.

## Single-buffer only

All Tree-sitter and buffer API calls use buffer `0` (current buffer). There is no multi-buffer support.

## Duplicate heading counter off-by-one

`toc.lua` appends `-N` suffixes to deduplicate repeated headings. The counter starts at `1` but the first duplicate is rendered with suffix `-1`, not `-2`. Be aware when reasoning about anchor collision behavior.
