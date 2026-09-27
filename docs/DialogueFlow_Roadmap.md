# DialogueFlow Roadmap

> Reusable Godot conversation system built with Rust + GDExtension, inspired by UEFN's conversation tooling.
>
> Core principle: **Rust implements the runtime and graph logic; Godot owns authoring, presentation, and integration.**
>
> This file is the project source of truth. Update the checklist as work is completed, then resend this file whenever context needs to be restored.

---

## Master Progress Checklist

- [x] Direction decided: reusable modular conversation system, not a game
- [x] Inspired by UEFN, but not a direct clone
- [x] Directed graph model chosen instead of a tree
- [x] Branch convergence required
- [x] Outgoing events/signals required
- [x] Incoming events/signals required
- [x] Runtime separated from UI
- [x] Conversation content must not be hardcoded in Rust
- [x] Visual Godot authoring is the end goal

- [x] Phase 0 — Naming & project skeleton
- [x] Phase 1 — Graph specification
- [x] Phase 2 — Core conversation Resources
- [ ] Phase 3 — Runtime controller
- [ ] Phase 4 — Generic dialogue UI
- [ ] Phase 5 — True branching
- [ ] Phase 6 — Branch convergence
- [ ] Phase 7 — Outgoing events
- [ ] Phase 8 — Incoming events
- [ ] Phase 9 — State & conditions
- [ ] Phase 10 — Additional flow nodes
- [ ] Phase 11 — Graph validation
- [ ] Phase 12 — Visual Godot graph editor
- [ ] Phase 13 — Editor quality of life
- [ ] Phase 14 — External/public API
- [ ] Phase 15 — Reusability test suite
- [ ] Phase 16 — Packaging & cleanup
- [ ] Version 1 complete

---

# Locked Architectural Decisions

- [x] Rust handles runtime execution, graph traversal, validation, state, and the public system API.
- [x] Godot handles authoring and presentation.
- [x] Conversation content is stored in Godot `Resource`s.
- [x] The conversation structure is a **directed graph**, not a tree.
- [x] Multiple branches may target the same node.
- [x] A special merge node is not required for branch convergence.
- [x] Conversations can emit generic events to external systems.
- [x] Conversations can receive generic events from external systems.
- [x] Game-specific actions are not hardcoded in the conversation runtime.
- [x] UI is separated from the runtime.
- [x] Editor layout data is separated from runtime graph semantics.
- [x] Runtime/data model is built before the visual graph editor.
- [x] Invalid graph configurations should produce useful errors.
- [x] The project is a reusable module/system, not a game-specific feature.

---

# Phase 0 — Naming & Project Skeleton

## Goals

- [x] Choose final project/module name.
- [x] Choose final runtime object terminology.
- [x] Create a clean Godot project.
- [x] Create a clean Rust crate/module.
- [x] Configure `godot-rust 0.5.5`.
- [x] Enable `register-docs`.
- [x] Establish folder/module structure.
- [x] Establish Godot-facing documentation rules.
- [x] Verify a minimal Rust class loads correctly in Godot.

## Working Terminology

Final names:

- Project/system: `DialogueFlow`
- Runtime object: `DialogueController`

The Rust crate is now split into `graph/`, `resources/`, and `runtime/`
modules (each a `mod.rs`), matching the architecture split in the README.
Godot-facing documentation rules are written up in
[`documentation-guidelines.md`](./documentation-guidelines.md).

## Milestone

- [x] Empty reusable dialogue module loads in Godot without errors.

---

# Phase 1 — Graph Specification

Before implementation, define exactly how the graph behaves.

## Graph Rules

All defined in [`graph-specification.md`](./graph-specification.md).

- [x] Define node identity system.
- [x] Define stable unique node IDs.
- [x] Define edge/connection representation.
- [x] Define graph entry semantics.
- [x] Define what happens when a node has no outgoing edge.
- [x] Define allowed connection types.
- [x] Define multiple incoming-edge behavior.
- [x] Define cycle/loop behavior.
- [x] Define termination behavior.
- [x] Define runtime errors vs editor validation errors.
- [x] Define how automatic nodes are traversed.
- [x] Define how player-choice nodes pause execution.

## Initial Node Vocabulary

Semantics defined for all ten in
[`graph-specification.md`](./graph-specification.md); implementation is
still Phase 2+ per node.

- [x] `Entry`
- [x] `Speech`
- [x] `Response`
- [x] `Event`
- [x] `Condition`
- [x] `Random`
- [x] `WaitForEvent`
- [x] `Reroute`
- [x] `Restart`
- [x] `End`

Not every node must be implemented immediately. This phase defines their semantics first.

## Suggested Basic Connection Model

```text
Entry      -> executable node
Speech     -> Response(s) OR next executable node
Response   -> executable node
Event      -> executable node
Condition  -> executable nodes
Random     -> executable nodes
Wait       -> executable node
Reroute    -> executable node
Restart    -> Entry
End        -> nothing
```

## Milestone

- [x] Written graph specification is complete enough to implement without inventing behavior during coding.

---

# Phase 2 — Core Conversation Resources

Build the authorable data model.

## Tasks

- [x] Create the root conversation/graph `Resource`. (`ConversationGraph`)
- [x] Create base graph-node representation. (sibling `Resource` subclasses — see [`graph-specification.md`](./graph-specification.md); gdext doesn't support inheriting one custom class from another, so there is no shared Rust base type)
- [x] Give every node a stable unique ID. (`id` field on every node type)
- [x] Store graph edges/connections. (`next_id` / `response_ids` / `fallback_id`, by ID)
- [x] Store editor positions separately from runtime semantics. (`editor_position` field, unused by traversal)
- [x] Implement `Entry`.
- [x] Implement `Speech`.
- [x] Implement `Response`.
- [x] Implement `End`.
- [x] Expose dialogue content through Godot Inspector.
- [x] Save/load conversations as `.tres`.
- [x] Verify dialogue edits do not require recompiling Rust.

## First Test Graph

```text
Entry
  |
  v
Speech
  |
  v
Response
  |
  v
Speech
  |
  v
End
```

## Milestone

- [x] A complete linear conversation can be authored with Godot resources and no dialogue text exists in Rust source.

Built and verified as `dialogue-flow-godot/dialogue_data/test_conversation.tres`.

---

# Phase 3 — Runtime Controller

Build the object that executes conversation graphs.

## Tasks

- [ ] Assign a conversation resource from the Inspector.
- [ ] Implement `start()`.
- [ ] Implement `stop()`.
- [ ] Implement `cancel()`.
- [ ] Track the current node.
- [ ] Traverse automatic nodes.
- [ ] Pause when player input is required.
- [ ] Implement response selection.
- [ ] Detect `End`.
- [ ] Handle broken/missing node references safely.
- [ ] Prevent accidental infinite automatic traversal.
- [ ] Reset runtime state on restart.

## Initial Signals

- [ ] `dialogue_started`
- [ ] `dialogue_finished`
- [ ] `dialogue_cancelled`
- [ ] `speech_changed`
- [ ] `responses_changed`

## Milestone

- [ ] Runtime can execute a complete linear conversation without knowing anything about the UI.

---

# Phase 4 — Generic Dialogue UI

Presentation stays separate from runtime logic.

## Tasks

- [ ] Create basic dialogue UI scene.
- [ ] Display speaker name.
- [ ] Display speech text.
- [ ] Dynamically create response buttons.
- [ ] Send selected responses to the runtime.
- [ ] Show UI when dialogue starts.
- [ ] Hide UI when dialogue ends.
- [ ] Handle cancellation.
- [ ] Keep presentation logic outside the graph runtime.

## Architecture

```text
ConversationGraph
       |
       v
DialogueController
       |
       | signals
       v
DialogueUI
```

## Milestone

- [ ] One conversation can be played completely through Godot UI.

---

# Phase 5 — True Branching

## Tasks

- [ ] Allow one speech node to expose multiple responses.
- [ ] Allow each response to target a different node.
- [ ] Traverse the selected branch.
- [ ] Support arbitrarily deep branches.
- [ ] Verify different choices produce different dialogue paths.

## Example

```text
               -> Speech B -> End
Speech A -> Choice
               -> Speech C -> End
```

## Milestone

- [ ] A player choice genuinely changes the conversation path.

---

# Phase 6 — Branch Convergence

Branch merging must be native to the graph.

## Tasks

- [ ] Permit multiple nodes to target the same node.
- [ ] Ensure runtime makes no parent/ownership assumption.
- [ ] Test two branches converging into one node.
- [ ] Test convergence after several nodes.
- [ ] Test convergence followed by another branch.

## Example

```text
            -> B --\
A -> Choice         -> D -> End
            -> C --/
```

No `MergeNode` is required.

## Milestone

- [ ] Independent branches can naturally reunite into the same flow.

---

# Phase 7 — Outgoing Events

Allow dialogue to affect external systems without knowing what those systems are.

## Tasks

- [ ] Implement `Event`.
- [ ] Give events a `StringName`/identifier.
- [ ] Support optional payload data.
- [ ] Emit a generic event signal from the runtime.
- [ ] Continue graph traversal after event emission.
- [ ] Keep game-specific actions outside the dialogue module.

## Example

```text
Speech
  |
  v
Event("give_key")
  |
  v
Speech
```

External system:

```text
DialogueController
        |
        | event_emitted("give_key")
        v
InventorySystem
```

## Milestone

- [ ] A conversation can trigger an unrelated game system without directly depending on it.

---

# Phase 8 — Incoming Events

Allow external systems to influence or resume dialogue.

## Tasks

- [ ] Add generic `receive_event()` API.
- [ ] Implement `WaitForEvent`.
- [ ] Pause traversal at `WaitForEvent`.
- [ ] Resume when matching event arrives.
- [ ] Ignore unrelated events safely.
- [ ] Decide payload semantics.
- [ ] Handle events received while no dialogue is active.

## Example

```text
NPC:
"Open the gate."
       |
       v
WaitForEvent("gate_opened")
       |
       v
NPC:
"Good. Come inside."
```

External system:

```text
GateSystem
    |
    v
DialogueController.receive_event("gate_opened")
```

## Milestone

- [ ] Dialogue can both emit and receive gameplay events.

---

# Phase 9 — State & Conditions

Add automatic branching based on runtime state.

## Tasks

- [ ] Define dialogue context/state model.
- [ ] Support named values/variables.
- [ ] Implement `Condition`.
- [ ] Add true branch.
- [ ] Add false branch.
- [ ] Allow external systems to modify dialogue state.
- [ ] Define supported basic value types.
- [ ] Keep game-specific logic outside the dialogue system.

## Example

```text
Condition: has_pass
       |
   ----+----
  true     false
   |         |
   v         v
"Enter."   "Leave."
```

## Milestone

- [ ] Conversation can branch automatically according to external/runtime state.

---

# Phase 10 — Additional Flow Nodes

Only after the core graph is stable.

## Tasks

- [ ] Implement `Random`.
- [ ] Implement `Restart`.
- [ ] Finalize explicit `End`.
- [ ] Implement graph-cycle runtime semantics.
- [ ] Implement `Reroute`.

`Reroute` should mainly exist for editor readability.

## Milestone

- [ ] Complex graphs can loop, restart, randomly branch, and remain manageable.

---

# Phase 11 — Graph Validation

Malformed conversations should fail clearly.

## Tasks

- [ ] Detect missing `Entry`.
- [ ] Detect invalid multiple entry points if only one is allowed.
- [ ] Detect dangling edges.
- [ ] Detect nonexistent node IDs.
- [ ] Detect illegal connection types.
- [ ] Detect unreachable nodes.
- [ ] Detect invalid response targets.
- [ ] Detect invalid conditions.
- [ ] Detect invalid event names.
- [ ] Detect invalid wait-event names.
- [ ] Warn about suspicious infinite loops.
- [ ] Distinguish errors from warnings.
- [ ] Produce useful Godot error messages.
- [ ] Expose validation API for editor tooling.

## Milestone

- [ ] Intentionally broken graphs explain exactly what is wrong.

---

# Phase 12 — Visual Godot Graph Editor

Target workflow: author conversations visually inside Godot.

Likely Godot editor pieces:

```text
EditorPlugin
GraphEdit
GraphNode
```

Rust remains responsible for data/runtime. GDScript may be used for editor integration where appropriate.

## Tasks

- [ ] Create custom `EditorPlugin`.
- [ ] Recognize dialogue graph resources.
- [ ] Open them in a dedicated editor.
- [ ] Render nodes visually.
- [ ] Render connections visually.
- [ ] Create nodes from a context menu.
- [ ] Delete nodes.
- [ ] Move nodes.
- [ ] Connect nodes.
- [ ] Disconnect nodes.
- [ ] Prevent invalid connections.
- [ ] Edit selected node properties.
- [ ] Persist node positions.
- [ ] Support zoom/pan.
- [ ] Support Undo/Redo.
- [ ] Highlight `Entry`.
- [ ] Visually distinguish node types.
- [ ] Display validation errors.

## Milestone

- [ ] A conversation can be created from scratch without manually editing raw resources.

---

# Phase 13 — Editor Quality of Life

## Tasks

- [ ] Node search/create menu.
- [ ] Duplicate nodes.
- [ ] Copy/paste.
- [ ] Multi-select.
- [ ] Delete selected graph region.
- [ ] Automatic unique IDs.
- [ ] Search/rename speakers.
- [ ] Search dialogue text.
- [ ] Jump to node by ID.
- [ ] Highlight invalid nodes.
- [ ] Highlight unreachable nodes.
- [ ] Reroute nodes.
- [ ] Optional comments/groups.
- [ ] Confirmation for destructive actions.
- [ ] Sensible default node sizes.
- [ ] Useful tooltips/documentation.

## Milestone

- [ ] Building a non-trivial conversation feels comfortable in Godot.

---

# Phase 14 — External/Public API

Formalize the system as something another game can depend on.

## Incoming API

Target API should cover:

- [ ] `start`
- [ ] `stop`
- [ ] `cancel`
- [ ] `choose`
- [ ] `receive_event`
- [ ] `set_value`
- [ ] `get_value`

## Outgoing API

Target signals should cover:

- [ ] `dialogue_started`
- [ ] `dialogue_finished`
- [ ] `dialogue_cancelled`
- [ ] `speech_changed`
- [ ] `responses_changed`
- [ ] `event_emitted`
- [ ] `node_entered`
- [ ] `node_exited`

## Documentation & Encapsulation

- [ ] Review the Godot-facing public API.
- [ ] Remove unnecessary exposed methods.
- [ ] Document every Godot-facing class.
- [ ] Document every exported property.
- [ ] Document every signal.
- [ ] Document every public Godot function.
- [ ] Keep internal Rust implementation private where possible.
- [ ] Verify another system can use DialogueFlow entirely through its public API.

## Milestone

- [ ] A game can use the module without knowing its internal implementation.

---

# Phase 15 — Reusability Test Suite

Build conversations specifically designed to expose bad assumptions.

## Tests

- [ ] Simple linear NPC.
- [ ] Multi-choice NPC.
- [ ] Branch-and-merge conversation.
- [ ] Conversation with outgoing events.
- [ ] Conversation waiting for an incoming event.
- [ ] Conditional conversation.
- [ ] Looping conversation.
- [ ] Random branch conversation.
- [ ] Same conversation reused by multiple controller instances.
- [ ] Restart after completion.
- [ ] Cancel midway and start again.
- [ ] Malformed graph tests.
- [ ] Verify no dialogue content is hardcoded in Rust.

## Final Integration Test Graph

```text
                         -> Response A -> Event --------\
Entry -> Speech -> Choice                              |
                         -> Response B -> Condition ----+
                                              |         |
                                             ...        |
                                                        v
                                                     Speech
                                                        |
                                                        v
                                                WaitForEvent
                                                        |
                                                        v
                                                     Random
                                                    /      \
                                               Speech    Speech
                                                    \      /
                                                     \    /
                                                      End
```

## Milestone

- [ ] One graph demonstrates branching, convergence, state, outgoing events, and incoming events together.

---

# Phase 16 — Packaging & Cleanup

## Tasks

- [ ] Clean Rust module structure.
- [ ] Clean Godot addon structure.
- [ ] Remove debugging code.
- [ ] Remove experimental APIs.
- [ ] Fix naming inconsistencies.
- [ ] Run `cargo fmt`.
- [ ] Run `cargo clippy`.
- [ ] Build without warnings.
- [ ] Write README.
- [ ] Document installation.
- [ ] Document basic usage.
- [ ] Include example conversation.
- [ ] Include architecture overview.
- [ ] Explain external event integration.
- [ ] Explain how to create custom UI.

## Milestone

- [ ] Module can be copied into another Godot project and understood without reading its source code.

---

# Version 1 STOP Point

DialogueFlow v1 is complete when:

- [ ] Conversations are authored visually in Godot.
- [ ] No conversation content is hardcoded in Rust.
- [ ] Linear dialogue works.
- [ ] Player choices work.
- [ ] Branching works.
- [ ] Branch convergence works.
- [ ] Conversations emit events.
- [ ] Conversations receive events.
- [ ] Conditions work.
- [ ] Runtime state works.
- [ ] Loops/restarts work.
- [ ] Graph validation works.
- [ ] Generic UI works.
- [ ] Visual graph editor works.
- [ ] Public API is documented.
- [ ] Module works independently from the test game.

After this point:

> **STOP adding features and evaluate the system before deciding on a v2.**

Not part of v1 unless deliberately added later:

- Localization pipeline
- Voice acting/audio synchronization
- Cinematic camera system
- Quest system
- Inventory system
- Multiplayer synchronization
- Save-game persistence
- Yarn/Ink importers
- Animation sequencing
- Localization databases

---

# Context Restore Notes

When resuming work in a new conversation:

1. Send this Markdown file.
2. Say which phase is currently active.
3. Update completed tasks using `[x]`.
4. Do not redesign completed phases unless a discovered technical limitation requires it.
5. Treat the **Locked Architectural Decisions** section as the source of truth.
6. Respect the **Version 1 STOP Point** and avoid feature creep.
