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
│   │       ├── dialogue-flow.gdextension
│   │       ├── dialogue_ui.tscn
│   │       └── dialogue_ui.gd
│   └── dev/
│       ├── dev_test.tscn
│       ├── dev_test.gd
│       └── dialogue_data/
│           ├── test_conversation.tres
│           └── test_branching.tres
│
├── dialogue-flow-rust/
│   ├── Cargo.lock
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── graph/
│       │   └── mod.rs
│       ├── resources/
│       │   ├── mod.rs
│       │   ├── entry.rs
│       │   ├── speech.rs
│       │   ├── response.rs
│       │   ├── end.rs
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

**Phases 0-5 are complete.** The project is moving into
**Phase 6 — Branch Convergence**.

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

---

## License

License has not been selected yet.

A license will be added before the project is considered ready for distribution.
