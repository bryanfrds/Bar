# Bar

A Bartender-style menu bar organizer for macOS. Public API only — no Screen
Recording, no Accessibility permission.

## Build & run

```sh
./build.sh                    # -> build/Bar.app
./build.sh release install    # -> /Applications/Bar.app (stable path for login item)
open build/Bar.app
pkill Bar
```

## How it hides icons

Status items lay out right-to-left. An item with an enormous `length` consumes
the entire visible bar to its left, pushing every item left of it past the
screen edge. So collapsing is "make the separator 10,000pt wide" and expanding
is "make it 24pt again". Dozer and Hidden Bar work the same way.

**Cmd-drag the ☰ separator** to choose the cut line: everything to its left
hides. macOS persists that position via `autosaveName`.

## Controls

- **Left-click** the chevron (or the empty strip while collapsed) — toggle
- **Right-click** the chevron — menu:
  - Auto-hide after 10s
  - Show on hover (expand when the pointer reaches the menu bar)
  - Open at Login
  - Quit

## How this differs from Bartender

Bartender screen-captures the menu bar and redraws icons in its own bar, which
is why it needs Screen Recording — and why its silent 2024 change of ownership
alarmed people. The tradeoff for not doing that:

- Hidden icons are genuinely off-screen, not shown in a second bar.
- No per-item rules ("show battery only under 20%"), no icon search, no
  spotlight-style triggers, no per-item reordering inside the hidden set.
- One cut point. Bartender's "always hidden" second section isn't implemented
  (it would just be a second separator item — a straightforward addition).
