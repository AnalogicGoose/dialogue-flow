# DialogueFlow

A reusable, modular conversation system for **Godot 4** built with **Rust** through [godot-rust](https://godot-rust.github.io/).

`DialogueFlow` is inspired by systems such as UEFN's Conversation tooling, but is designed specifically around Godot's workflow and extensibility. The goal is not to build a game-specific dialogue script, but a reusable conversation framework that can be configured visually in Godot and integrated with other gameplay systems through a clean public API.

> **Status:** Early development / architecture phase.

---

## Goals

`DialogueFlow` aims to provide a conversation system where dialogue content is authored in Godot rather than hardcoded in Rust.

The system is designed around a **directed conversation graph**, allowing conversations to branch, converge, loop, react to game state, emit events, and wait for events from other systems.

Planned capabilities include:

- Branching conversations
- Multiple player responses
- Branch convergence
- Conversation events
- Incoming external events
- Conditions and runtime state
- Random branches
- Conversation restart/loop support
- Graph validation
- Reusable dialogue UI
- Godot Resources for conversation data
- A visual graph editor inside the Godot editor
- A reusable public API for integration with other systems

---

## Core Design

The project follows one central rule:

> **Rust implements the system. Godot owns the content and authoring workflow.**

Conversation text, speakers, choices, graph connections, and other content should be editable through Godot without recompiling the Rust library.

The architecture is intentionally split into separate responsibilities:

```text
Conversation Resources
        |
        v
Conversation Graph
        |
        v
Rust Runtime
        |
        +------> Dialogue UI
        |
        +------> External Game Systems
```

### Rust

Rust is responsible for:

- Conversation graph execution
- Graph traversal
- Runtime state
- Conditions
- Event handling
- Graph validation
- Public runtime API
- Godot-facing signals and functions

### Godot

Godot is responsible for:

- Conversation authoring
- `.tres` Resources
- Visual presentation
- Dialogue UI
- Editor tooling
- Visual graph editing
- Connecting conversation events to game-specific systems

---

## Conversation Graph

A conversation is modeled as a **directed graph**, not a tree.

This allows different branches to naturally reconnect to the same node:

```text
            +--> Branch A --+
            |               |
Entry ------+               +--> Shared Dialogue --> End
            |               |
            +--> Branch B --+
```

No special merge node is required. Multiple nodes may simply reference the same destination.

The planned graph vocabulary includes:

- `Entry`
- `Speech`
- `Response`
- `Event`
- `Condition`
- `Random`
- `WaitForEvent`
- `Reroute`
- `Restart`
- `End`

---

## System Integration

`DialogueFlow` is intended to communicate with the rest of a game through generic signals and functions rather than hardcoded gameplay behavior.

For example, a conversation may emit:

```text
give_key
open_gate
quest_accepted
boss_defeated
```

The dialogue system does not need to know what those events mean. External systems decide how to react.

Likewise, conversations will be able to receive external events:

```text
GateSystem
    |
    v
Dialogue Runtime
    |
    v
WaitForEvent("gate_opened")
```

This keeps the conversation system independent from inventory, quests, combat, world logic, and other game-specific systems.

---

## Planned Runtime API

The exact API is still being designed, but the runtime is expected to expose functionality similar to:

```text
start()
stop()
cancel()
choose(...)
receive_event(...)
set_value(...)
get_value(...)
```

And signals similar to:

```text
dialogue_started
dialogue_finished
dialogue_cancelled

speech_changed
responses_changed

event_emitted
node_entered
node_exited
```

Names may change as the API is finalized.

---

## Visual Editor

The long-term authoring goal is a dedicated Godot graph editor built around Godot's editor APIs, likely using:

- `EditorPlugin`
- `GraphEdit`
- `GraphNode`

The intended workflow is similar to:

```text
[Entry]
   |
   v
[Speech: Guard]
   |
   +-------------------+
   |                   |
   v                   v
[Response A]       [Response B]
   |                   |
   v                   v
[Event]            [Condition]
   |                   |
   +---------+---------+
             |
             v
      [Shared Speech]
             |
             v
            [End]
```

The graph editor will eventually handle node creation, connection rules, validation, node positioning, Undo/Redo, and other authoring features.

---

## Repository Structure

Current project structure:

```text
.
├── dialogue-flow-godot/
│   ├── icon.svg
│   ├── project.godot
│   ├── addons/
│   │   └── dialogue_flow/
│   │       ├── plugin.cfg
│   │       ├── dialogue-flow.gdextension
│   │       ├── dialogue_ui.tscn
│   │       ├── dialogue_ui.gd
│   │       ├── bin/            (gitignored; built by `cargo build-addon`)
│   │       │   └── linux|windows|macos/
│   │       └── editor/
│   │           ├── dialogue_flow_editor_plugin.gd
│   │           ├── graph_editor.gd
│   │           ├── dialogue_graph_edit.gd
│   │           └── node_visuals/
│   │               ├── node_visual.gd
│   │               ├── entry_visual.gd
│   │               ├── speech_visual.gd
│   │               ├── response_visual.gd
│   │               ├── event_visual.gd
│   │               ├── condition_visual.gd
│   │               ├── random_visual.gd
│   │               ├── wait_for_event_visual.gd
│   │               ├── reroute_visual.gd
│   │               ├── restart_visual.gd
│   │               └── end_visual.gd
│   └── dev/
│       ├── dev_test.tscn
│       ├── dev_test.gd
│       ├── validate_all.gd
│       └── dialogue_data/
│           ├── basics/
│           │   └── test_conversation.tres
│           ├── branching/
│           │   ├── test_branching.tres
│           │   └── test_convergence.tres
│           ├── events/
│           │   ├── test_events.tres
│           │   └── test_wait_event.tres
│           ├── state/
│           │   ├── test_condition.tres
│           │   └── test_conditional_response.tres
│           └── flow/
│               ├── test_restart.tres
│               ├── test_random.tres
│               └── test_reroute.tres
│
├── dialogue-flow-rust/
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── .cargo/
│   │   └── config.toml   (defines the `cargo build-addon` alias)
│   └── src/
│       ├── lib.rs
│       ├── bin/
│       │   └── build_addon.rs
│       ├── graph/
│       │   └── mod.rs
│       ├── resources/
│       │   ├── mod.rs
│       │   ├── entry.rs
│       │   ├── speech.rs
│       │   ├── response.rs
│       │   ├── end.rs
│       │   ├── event.rs
│       │   ├── wait_for_event.rs
│       │   ├── condition.rs
│       │   ├── random.rs
│       │   ├── restart.rs
│       │   ├── reroute.rs
│       │   └── graph.rs
│       └── runtime/
│           └── mod.rs
│
├── docs/
│   ├── DialogueFlow_Roadmap.md
│   ├── graph-specification.md
│   └── documentation-guidelines.md
├── README.md
└── .gitignore
```

The repository intentionally keeps the Godot project and Rust crate separate.

### `dialogue-flow-godot`

- `addons/dialogue_flow/` — the portable module itself: the `.gdextension`
  wiring today, and where the future `EditorPlugin` (Phase 12) will live.
  This is what would get copied into another Godot project.
- `dev/` — this repo's own scratch/test harness (manual smoke-test scene
  and test conversation data). Not part of the module; never shipped.

### `dialogue-flow-rust`

Contains:

- GDExtension implementation
- Conversation resources exposed from Rust
- Graph runtime
- Validation
- Public API

During development, `dialogue-flow.gdextension` points straight at the
addon's own `bin/` folder rather than `target/`, so run `cargo build-addon`
(alias for `cargo run --bin build_addon --`, in `dialogue-flow-rust/`)
instead of a plain `cargo build` — it builds the library and copies it into
`dialogue-flow-godot/addons/dialogue_flow/bin/<platform>/`. This keeps
`addons/dialogue_flow/` self-contained: it's what would actually get zipped
up for the Asset Library, with no dependency on `dialogue-flow-rust/`
existing alongside it. Defaults to a release build; `cargo build-addon debug`
builds the debug profile instead. `bin/` is gitignored and rebuilt on demand,
not committed on every change.

---

## Requirements

Current development target:

- **Godot 4**
- **Rust**
- **godot-rust 0.5.5**

The Rust dependency is intended to use the `register-docs` feature so Godot-facing Rust classes, exported properties, signals, and functions can provide documentation inside Godot.

Example dependency:

```toml
[dependencies]
godot = { version = "0.5.5", features = ["register-docs"] }
```

---

## Getting Started

To run this repo locally (as opposed to just reading it):

1. **Build the GDExtension.** From `dialogue-flow-rust/`:

   ```sh
   cargo build-addon
   ```

   This compiles the Rust crate and copies the resulting library into
   `dialogue-flow-godot/addons/dialogue_flow/bin/<platform>/`, which is
   where the addon's `.gdextension` file expects to find it — a plain
   `cargo build` compiles the crate but leaves the binary in `target/`,
   where Godot won't see it. Pass `debug` for a debug build
   (`cargo build-addon debug`); the default is `release`. See
   `dialogue-flow-rust/src/bin/build_addon.rs` for what it's actually doing.

2. **Open the Godot project.** Point Godot 4 at
   `dialogue-flow-godot/project.godot`. The `DialogueFlow` editor plugin is
   already enabled in `project.godot`, so no manual "enable plugin" step
   is needed — after step 1, its main-screen tab and the `EntryNode`/
   `SpeechNode`/etc. resource types should just work.

3. **Try it.** `dev/dialogue_data/` has test `ConversationGraph` resources
   grouped by topic (`basics/`, `branching/`, `events/`, `state/`,
   `flow/`) — double-click one in the FileSystem dock to open it in the
   visual editor. `dev/dev_test.tscn` is a runnable scene wired to
   `test_reroute.tres` through the generic `DialogueUI`, for playing a
   conversation end-to-end rather than just editing its graph.

If you change the Rust code, re-run `cargo build-addon` and reload the
project (or use Godot's "Reload current project") to pick up the new
binary — the `.gdextension` config has `reloadable = true`, but a change
to the compiled library itself still needs a fresh build first.

---

## Development Principles

### Editor-first content

Conversation content should be configurable through Godot.

Avoid:

```rust
if choice == 0 {
    println!("Hello traveler!");
}
```

Prefer data-driven conversation Resources authored in Godot.

### Runtime and UI remain separate

The runtime should not depend on one specific dialogue box or visual style.

A project should be able to replace the UI without rewriting the conversation engine.

### Game-specific systems remain external

The conversation system should not directly implement:

- Inventory
- Quests
- Combat
- Doors
- NPC AI
- Save systems

Instead, it communicates through generic events and state.

### Invalid graphs should fail clearly

Broken graph configurations should produce useful validation errors rather than silently failing at runtime.

### No unnecessary feature creep

The first version has a defined stopping point. Features such as localization pipelines, voice acting synchronization, quest systems, multiplayer replication, save persistence, or Yarn/Ink importers are outside the initial scope unless explicitly planned for a later version.

---

## Roadmap

Development is tracked in:

[`docs/DialogueFlow_Roadmap.md`](./docs/DialogueFlow_Roadmap.md)

The roadmap is the project's source of truth and contains:

- Master progress checklist
- Locked architecture decisions
- Development phases
- Milestones
- Version 1 stopping point

---

## Current Status

**Phases 0-12 are complete.** The project is moving into
**Phase 13 — Editor Quality of Life**.

Completed so far:

- [x] Project name chosen: `DialogueFlow`
- [x] Runtime object name chosen: `DialogueController`
- [x] Clean Godot project created
- [x] Clean Rust crate created
- [x] Repository split into Godot and Rust directories
- [x] High-level system architecture defined
- [x] Directed graph model chosen
- [x] Branch convergence established as a core requirement
- [x] Incoming and outgoing event support established as core requirements
- [x] Configure godot-rust
- [x] Enable Rust documentation registration
- [x] Establish initial Rust module structure (`graph/`, `resources/`, `runtime/`)
- [x] Verify the first Rust class loads in Godot
- [x] Written graph specification (see [`docs/graph-specification.md`](./docs/graph-specification.md))
- [x] `EntryNode`, `SpeechNode`, `ResponseNode`, `EndNode`, and `ConversationGraph` implemented as `Resource` subclasses
- [x] First linear test conversation authored and saved as `.tres`, with no dialogue text in Rust source
- [x] `DialogueController` implemented: `start()`/`stop()`/`cancel()`/`choose()`, automatic traversal, pausing on player choice, and all five initial signals
- [x] Runtime verified end-to-end against the test conversation, entirely through signals, with no UI involved
- [x] Generic `DialogueUI` scene (`addons/dialogue_flow/dialogue_ui.tscn`) implemented: displays speaker/text, builds response buttons dynamically, shows/hides on start/finish/cancel
- [x] Full conversation played manually through the Godot UI, start to `End`
- [x] True branching verified: a single `Speech` with two `Response`s leads to two fully separate tails, confirmed to diverge correctly end-to-end
- [x] Branch convergence verified: independent branches reunite into the same node with no `MergeNode`, then branch again from the merge point
- [x] `EventNode` implemented: fires a named event with an optional payload (`event_emitted`) and continues traversal automatically, with no game-specific logic in the dialogue module
- [x] `WaitForEventNode` and `receive_event()` implemented: dialogue can pause until a matching external event arrives, ignoring unrelated events and idle calls safely
- [x] `ConditionNode` and `set_value()`/`get_value()` implemented: conversations branch on named state that persists across `start()`/`stop()`/`cancel()`
- [x] Conditional response visibility: a `Response` can require a state variable to be truthy to appear, with index selection kept consistent between what's displayed and what's chosen
- [x] `RandomNode`, `RestartNode`, and `RerouteNode` implemented: weighted random branches, looping back to `Entry`, and a transparent passthrough node, all verified against the real project
- [x] `ConversationGraph::validate()` implemented: static checks for missing/duplicate `Entry`, dangling/illegal edges, invalid response targets, unreachable nodes, and cycles with no pausing node — caught a real, previously-undetected bug in existing test content
- [x] Custom `EditorPlugin` (`addons/dialogue_flow/editor/`) implemented: `ConversationGraph` resources open on their own main-screen tab as an editable `GraphEdit` — create/delete/connect/disconnect nodes (right-click or drag-release-from-a-pin, with a searchable node-type popup and live invalid-connection rejection), move nodes, edit properties via the native Inspector, color-coded by node type, `Entry` highlighted, validation errors shown per node, New/Open/Save/Close toolbar, all changes Ctrl+Z/Ctrl+S-integrated through `EditorUndoRedoManager`
- [x] `addons/dialogue_flow/` made self-contained for distribution: the `.gdextension` loads from `addons/dialogue_flow/bin/<platform>/` rather than the sibling Rust crate's `target/`; `cargo build-addon` (in `dialogue-flow-rust/`) builds and copies the library there

---

## License

License has not been selected yet.

A license will be added before the project is considered ready for distribution.
