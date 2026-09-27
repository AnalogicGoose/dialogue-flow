# Documentation Guidelines

Rules for documenting the Rust crate now that `register-docs` is enabled, so
Godot's built-in help (Inspector tooltips, the Script docs tab) stays useful
without a separate doc-writing pass later.

## Godot-facing items

Anything visible to Godot — `#[derive(GodotClass)]` types, `#[func]`
methods, `#[var]` properties, `#[signal]` declarations — gets a `///` doc
comment:

- First line: a single, concise sentence. This is what shows up in Godot's
  search/help panel, so it must stand alone.
- Blank line, then optional detail: parameters, return value, side effects,
  related signals or nodes.

```rust
/// Starts the conversation from its `Entry` node.
///
/// Emits `dialogue_started`. Does nothing if a conversation is already
/// running; call [`stop`] first.
#[func]
fn start(&mut self) { ... }
```

## Internal (non-Godot-facing) items

Regular Rust items follow normal rustdoc conventions. A `///` comment is
only required when the item is `pub` across a module boundary; private
helpers don't need one unless the *why* isn't obvious from the code.

## Modules

Each module's `mod.rs` starts with a `//!` comment stating what the module
owns and, briefly, what it explicitly does not do — mirroring the
responsibility split in the [architecture overview](../README.md#core-design).
See `src/graph/mod.rs`, `src/resources/mod.rs`, and `src/runtime/mod.rs` for
the current examples.

## Division of labor with the roadmap and README

- Doc comments in code describe **how** a specific item works.
- The [roadmap](./DialogueFlow_Roadmap.md) and README describe **why** and
  **current status**.

Don't duplicate one in the other — link instead.
