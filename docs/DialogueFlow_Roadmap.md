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
- [x] Phase 3 — Runtime controller
- [x] Phase 4 — Generic dialogue UI
- [x] Phase 5 — True branching
- [x] Phase 6 — Branch convergence
- [x] Phase 7 — Outgoing events
- [x] Phase 8 — Incoming events
- [x] Phase 9 — State & conditions
- [x] Phase 10 — Additional flow nodes
- [x] Phase 11 — Graph validation
- [x] Phase 12 — Visual Godot graph editor
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

- [x] Assign a conversation resource from the Inspector. (`#[export] conversation: Option<Gd<ConversationGraph>>`)
- [x] Implement `start()`.
- [x] Implement `stop()`.
- [x] Implement `cancel()`.
- [x] Track the current node. (`current_id`)
- [x] Traverse automatic nodes. (`Entry`, `Response`, and `Speech` with no responses)
- [x] Pause when player input is required. (`Speech` with ≥1 response)
- [x] Implement response selection. (`choose(index)`)
- [x] Detect `End`.
- [x] Handle broken/missing node references safely. (dangling ID → `godot_error!` + reset, never a panic)
- [x] Prevent accidental infinite automatic traversal. (`MAX_AUTOMATIC_STEPS` guard)
- [x] Reset runtime state on restart. (`start()` always resets first)

## Initial Signals

- [x] `dialogue_started`
- [x] `dialogue_finished`
- [x] `dialogue_cancelled`
- [x] `speech_changed`
- [x] `responses_changed`

## Milestone

- [x] Runtime can execute a complete linear conversation without knowing anything about the UI.

Verified headless against `dialogue-flow-godot/dialogue_data/test_conversation.tres`: `start()` pauses on the `Response`, `choose(0)` resumes through the fallback `Speech` into `End`, and `cancel()` mid-conversation emits `dialogue_cancelled` — all via signals, with no UI involved.

---

# Phase 4 — Generic Dialogue UI

Presentation stays separate from runtime logic.

## Tasks

- [x] Create basic dialogue UI scene. (`addons/dialogue_flow/dialogue_ui.tscn`)
- [x] Display speaker name.
- [x] Display speech text.
- [x] Dynamically create response buttons.
- [x] Send selected responses to the runtime. (`Button.pressed` → `controller.choose(i)`)
- [x] Show UI when dialogue starts.
- [x] Hide UI when dialogue ends.
- [x] Handle cancellation. (`dialogue_cancelled` routes to the same hide as `dialogue_finished`)
- [x] Keep presentation logic outside the graph runtime. (`DialogueUI` only touches `DialogueController`'s signals and `choose()`, never its internal state)

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

- [x] One conversation can be played completely through Godot UI.

Verified manually in the editor: `dev/dev_test.tscn` (`DialogueController` +
a `dialogue_ui.tscn` instance) plays the test conversation end to end —
speech and responses display, choosing a response advances it, and it
reaches `End`.

---

# Phase 5 — True Branching

## Tasks

- [x] Allow one speech node to expose multiple responses. (already generic since Phase 2/3; `response_ids` was never capped at one)
- [x] Allow each response to target a different node.
- [x] Traverse the selected branch.
- [x] Support arbitrarily deep branches. (verified 2 levels: `Speech → Response → Speech → Response → End`)
- [x] Verify different choices produce different dialogue paths.

## Example

```text
               -> Speech B -> End
Speech A -> Choice
               -> Speech C -> End
```

## Milestone

- [x] A player choice genuinely changes the conversation path.

Verified with `dev/dialogue_data/test_branching.tres`: `Guard: "Which way
will you go?"` branches on `choose(0)` vs `choose(1)` into two entirely
separate `Speech → "Continue..." → End` tails, confirmed both headlessly
(driving `DialogueController` directly) and manually in the editor.
Caught and fixed a copy-paste authoring bug along the way (one branch's
response pointed at the other branch's `Continue...` node) — a reminder
that two `End`s look identical at runtime, so divergence needs checking
by tracing IDs, not just "does it still end."

---

# Phase 6 — Branch Convergence

Branch merging must be native to the graph.

## Tasks

- [x] Permit multiple nodes to target the same node. (already generic since Phase 2/3; nodes are addressed purely by ID, nothing tracks a parent)
- [x] Ensure runtime makes no parent/ownership assumption.
- [x] Test two branches converging into one node.
- [x] Test convergence after several nodes.
- [x] Test convergence followed by another branch.

## Example

```text
            -> B --\
A -> Choice         -> D -> End
            -> C --/
```

No `MergeNode` is required.

## Milestone

- [x] Independent branches can naturally reunite into the same flow.

Verified with `dev/dialogue_data/test_convergence.tres` (14 nodes): the
left and right paths (each 2 hops deep) reunite at `speech_merge`, which
then branches again into knock/leave, and both of *those* reconverge on
one shared `End`. All four combinations (left/right × knock/leave) were
driven directly through `DialogueController` and confirmed correct.
Caught and fixed another authoring bug along the way — one branch used
`fallback_id` pointing at a `ResponseNode`, which is an illegal
connection per the spec (Phase 11 validation would catch this once
built; for now it happens to still traverse, just silently skipping the
pause the author intended).

---

# Phase 7 — Outgoing Events

Allow dialogue to affect external systems without knowing what those systems are.

## Tasks

- [x] Implement `Event`. (`EventNode`, `dialogue-flow-rust/src/resources/event.rs`)
- [x] Give events a `StringName`/identifier. (`event_name: StringName`)
- [x] Support optional payload data. (`payload: Dictionary<GString, Variant>`, defaults empty)
- [x] Emit a generic event signal from the runtime. (`event_emitted(event_name, payload)`)
- [x] Continue graph traversal after event emission. (never pauses, same automatic pattern as `Entry`/`Response`)
- [x] Keep game-specific actions outside the dialogue module. (the runtime only carries the name/payload — it never interprets what "give_key" means)

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

- [x] A conversation can trigger an unrelated game system without directly depending on it.

Verified with `dev/dialogue_data/test_events.tres`: `Entry → Event("give_key", {"amount": 1}) → Speech → End`,
driven directly through `DialogueController` and confirmed against the
real project. `event_emitted` carries the name and payload correctly and
traversal continues normally — no game-specific logic lives in the
runtime or the node itself.

Note: the payload-identification gap flagged in Phase 14's Observability
section doesn't apply to `Event` — `event_emitted` already carries what's
needed (name + payload). It's `dialogue_finished`/`node_entered`/`node_exited`
that are the actual gap, not this signal.

---

# Phase 8 — Incoming Events

Allow external systems to influence or resume dialogue.

## Tasks

- [x] Add generic `receive_event()` API.
- [x] Implement `WaitForEvent`. (`WaitForEventNode`, `dialogue-flow-rust/src/resources/wait_for_event.rs`)
- [x] Pause traversal at `WaitForEvent`.
- [x] Resume when matching event arrives.
- [x] Ignore unrelated events safely. (not running, wrong node, or wrong event name → silent no-op, never `godot_error!`)
- [x] Decide payload semantics. `receive_event` accepts a `Dictionary<GString, Variant>` payload for symmetry with `event_emitted`, but it isn't consumed anywhere yet — there's no state/variable system to put it in until Phase 9.
- [x] Handle events received while no dialogue is active. (`receive_event` on an idle controller is a no-op, verified)

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

- [x] Dialogue can both emit and receive gameplay events.

Verified with `dev/dialogue_data/test_wait_event.tres` (the roadmap's own
example graph), driven directly through `DialogueController`: pauses
silently at `WaitForEvent`, ignores a wrong event name while waiting,
resumes correctly on the matching event, and a fresh idle controller
doesn't error on `receive_event()`.

Fixed a real UI bug found while testing manually: entering
`WaitForEventNode` emitted no signal at all, so `DialogueUI`'s response
buttons from the prior `Speech` were never cleared — clicking the stale
button then hit `choose()` on a non-`Speech` node. Fixed by emitting
`responses_changed` with an empty array on pause, reusing the existing
signal rather than adding a new one; `DialogueUI` needed no changes since
it already clears buttons before rebuilding.

Design note (from a user question): `WaitForEvent` only ever resumes to
one `next_id` — it cannot branch on its own. A branch gated by "what
happened" is meant to compose as `WaitForEvent → Condition`, where Phase
9's state system is what actually decides the branch; `WaitForEvent`'s
job is only "pause until *something* happens," not "decide what to do
based on *what* happened."

---

# Phase 9 — State & Conditions

Add automatic branching based on runtime state.

## Tasks

- [x] Define dialogue context/state model. A `HashMap<StringName, Variant>` owned by each `DialogueController` instance — state belongs to the controller, not to a single conversation run.
- [x] Support named values/variables. (`set_value`/`get_value`)
- [x] Implement `Condition`. (`ConditionNode`, `dialogue-flow-rust/src/resources/condition.rs`)
- [x] Add true branch.
- [x] Add false branch.
- [x] Allow external systems to modify dialogue state. (`DialogueController::set_value`, public `#[func]`)
- [x] Define supported basic value types. Anything `Variant` can hold is technically storable, but the intended authored set is `bool`/`int`/`float`/`String` — simple values a `Condition` can meaningfully branch on.
- [x] Keep game-specific logic outside the dialogue system. (the runtime only checks truthiness; it never interprets what a variable *means*)

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

- [x] Conversation can branch automatically according to external/runtime state.

Verified with `dev/dialogue_data/test_condition.tres` (the roadmap's own
`has_pass` example): unset, true, and false all branch correctly, and
state was confirmed to persist across `cancel()`/`start()`, driven
directly through `DialogueController` against the real project.

## Extension: Conditional Response Visibility

Not an original Phase 9 task, but added here because it directly reuses
everything this phase built: a `ResponseNode` can set
`required_variable: StringName` (empty = always visible) so a single
`Speech` can offer a response only once some state variable is truthy —
e.g. a "Show me the secret stock." option that only appears once
`has_key` is set. This is distinct from `Condition`, which branches the
*entire path* before a `Speech`; this instead hides/shows individual
options *within* one `Speech`'s response list, letting "complete
branches" (whatever a hidden response leads to) become available only
once something has happened — closer to how UEFN's dialogue options can
be conditionally gated.

Two consequences worth remembering:
- `choose(index)` and the displayed list must filter *identically*
  (`DialogueController::visible_response_ids`), or a hidden response
  shifting the list would make `choose()` pick the wrong node.
- If **all** of a `Speech`'s responses are currently hidden, it's treated
  the same as having none at all and falls through to `fallback_id` —
  so a `Speech` with only conditional options never dead-ends as long as
  it also has a fallback.

Verified with `dev/dialogue_data/test_conditional_response.tres`: a
Merchant's third response ("Show me the secret stock.") only appears once
`has_key` is set, index selection stays correct in both states, and (from
an earlier scratch test) a `Speech` with only a hidden response correctly
falls through to its `fallback_id`.

---

# Phase 10 — Additional Flow Nodes

Only after the core graph is stable.

## Tasks

- [x] Implement `Random`. (`RandomNode` + `RandomBranch`, weighted selection via `godot::global::randf_range`)
- [x] Implement `Restart`. (`RestartNode`; reuses the exact same entry-lookup as `start()` via a shared `find_entry_id()` helper)
- [x] Finalize explicit `End`. No changes needed — already complete since Phase 2; still the only legal dead end now that four more automatic node types exist.
- [x] Implement graph-cycle runtime semantics. Already covered by Phase 3's `MAX_AUTOMATIC_STEPS` guard; re-confirmed against an intentionally infinite `Reroute → Reroute` cycle (errors and resets safely, never hangs).
- [x] Implement `Reroute`. (`RerouteNode`, pure passthrough)

`Reroute` should mainly exist for editor readability.

Worth recording since it came up repeatedly while testing: `Reroute` is
*always* removable/replaceable by direct wiring with zero behavior
change — that's not a design flaw, it's the definition of the node. It
has no runtime purpose at all yet; its entire value is visual, for
bending a wire around clutter once the Phase 12 graph editor exists. Any
test built now will necessarily show "it does nothing" — the actual
property worth verifying is that it's *transparent* (behaves identically
to direct wiring), which was confirmed via a single-hop passthrough, a
2-hop chain, and a 3-node infinite-loop cycle-cap test.

## Milestone

- [x] Complex graphs can loop, restart, randomly branch, and remain manageable.

Verified against the real project: `test_restart.tres` loops via
`Restart` and exits correctly; `test_random.tres`'s 3:1 weighted branches
landed ~75/25 over 500 runs (a 0-weight branch was separately confirmed
to never fire, across 500 runs, in scratch testing); `test_reroute.tres`
confirms a `Reroute` participates correctly in a `Speech`-driven loop
without being load-bearing to it.

---

# Phase 11 — Graph Validation

Malformed conversations should fail clearly.

## Tasks

- [x] Detect missing `Entry`. (error)
- [x] Detect invalid multiple entry points if only one is allowed. (error; names every EntryNode found)
- [x] Detect dangling edges. (error; any `*_id` field pointing at a nonexistent node)
- [x] Detect nonexistent node IDs. Interpreted as **duplicate node IDs** (distinct from dangling edges — see note below). (error)
- [x] Detect illegal connection types. (error; any generic edge targeting `Entry` or `Response`, per the connection-legality rule)
- [x] Detect unreachable nodes. (warning; BFS from Entry over every *possible* edge, not just the one that would be taken at runtime)
- [x] Detect invalid response targets. (error; a `response_ids` entry that doesn't resolve to an actual `ResponseNode`)
- [x] Detect invalid conditions. (warning for empty `variable_name`; `true_id`/`false_id` covered by the general edge checks)
- [x] Detect invalid event names. (warning for empty `event_name` on `EventNode`)
- [x] Detect invalid wait-event names. (warning for empty `event_name` on `WaitForEventNode`)
- [x] Warn about suspicious infinite loops. (warning; DFS cycle detection restricted to non-pausing nodes only — see graph-specification.md's cycle-safety section)
- [x] Distinguish errors from warnings. (`ConversationGraph::validate()` returns both as separate lists)
- [x] Produce useful Godot error messages. (every message names the specific offending node id and field)
- [x] Expose validation API for editor tooling. (`ConversationGraph::validate() -> Dictionary` with `errors`/`warnings`, callable from GDScript now, ready for Phase 12's editor to call)

**Interpretation note:** "Detect nonexistent node IDs" was ambiguous
against "Detect dangling edges." Implemented as **duplicate ID
detection** instead of a repeat of the dangling-edge check, since two
nodes sharing an ID silently corrupts `DialogueController`'s
`node_index` (one overwrites the other) with nothing else to catch it.

**Errors vs. warnings:** errors mean the graph can't be trusted to run
correctly (missing/duplicate Entry, dangling/illegal edges, a
`response_ids` entry that isn't a Response, a Speech that's a guaranteed
dead end, an empty or duplicate id, a Random with no branches or zero
total weight). Warnings mean it'll probably still run, but something
looks like a mistake (empty event/variable names, a negative branch
weight, an unreachable node, a cycle with no pausing node).

**Deliberate scope limit:** the cycle check treats any `Speech` with
`response_ids` (and any `WaitForEvent`) as "pausing," even though Phase
9's conditional visibility could make all of a Speech's responses hidden
at runtime and let it fall through anyway. That's runtime-state-dependent
and unknowable statically, so the checker stays conservative rather than
risk a false "this can't loop" — the `MAX_AUTOMATIC_STEPS` runtime guard
from Phase 3 remains the actual safety net for that specific edge case.

## Milestone

- [x] Intentionally broken graphs explain exactly what is wrong.

Verified against 12 deliberately broken graphs (one per major check) plus
one fully valid graph (zero false positives), run directly against the
real project. Running `validate()` against all ten existing test graphs
caught a **real, previously-undetected bug**: `test_condition.tres`'s
`speech_leave` had `fallback_id` pointing at a `ResponseNode` — illegal,
and silent, since the runtime doesn't enforce the rule (only static
validation does). It had gone unnoticed since Phase 9 because it still
"worked" — it just silently skipped its intended pause. Fixed to use
`response_ids` instead, matching the sibling `speech_enter` node.

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

## Design Reference: Unreal Blueprint

The target UX is Unreal's Blueprint graph editor, not a generic node
canvas. Concretely, that means:

- **Drag-release node creation.** Dragging a wire out from a pin and
  releasing it over empty canvas opens a searchable menu of compatible
  node types; picking one creates the node already wired to where the
  drag started. This is the primary way nodes get created — a plain
  right-click-canvas menu (already listed below) is the fallback, not
  the main path.
- **Manual cleanup actions, not automatic layout** (already the decision
  behind [retiring the DFS auto-layout](#notes-from-building-the-read-only-visualizer)):
  "Straighten Connections" on a wire or selection, plus
  Align Top/Middle/Bottom/Left/Center/Right and Distribute
  Horizontally/Vertically on a multi-selection — targeted, user-invoked,
  never something that runs on load.
- **Double-click a wire to insert a `Reroute`** at that point, already
  connected on both sides — this is `Reroute`'s actual authoring path,
  not manually placing one and rewiring two edges by hand.
- **Validation surfaces on the graph itself, not just a console.**
  `ConversationGraph::validate()` (Phase 11) already returns structured
  errors/warnings per node — Phase 12's "Display validation errors" task
  means rendering those as an error/warning icon or outline directly on
  the offending `GraphNode`, matching Blueprint's compile-error markers,
  not a separate log panel the author has to cross-reference by id.
- **Connections rejected live while dragging, not after.**
  `GraphEdit.connection_request` lets us check the
  connection-legality rule (no edge may target `Entry`/`Response`) and
  simply refuse to complete an illegal drag, the same way Blueprint
  greys out/refuses incompatible pins mid-drag — not connect-then-error.
- **Color-coded nodes by category**, the same way Blueprint colors events
  red, flow control grey, pure functions blue/teal: each of our node
  types should get a consistent color so the graph is scannable at a
  glance (exact palette TBD when this is built).
- **`Condition`'s two outputs behave like Blueprint's Branch node** —
  labeled/colored `True`/`False` pins, not two identical anonymous slots.

## Tasks

- [x] Create custom `EditorPlugin`. (`addons/dialogue_flow/editor/dialogue_flow_editor_plugin.gd`)
- [x] Recognize dialogue graph resources. (`_handles()` matches `ConversationGraph`)
- [x] Open them in a dedicated editor. (a main-screen tab, next to 2D/3D/Script/AssetLib — not a bottom panel, see notes below)
- [x] Render nodes visually. (`addons/dialogue_flow/editor/graph_editor.gd`, a `GraphEdit` populated from `ConversationGraph.nodes`)
- [x] Render connections visually. (every `*_id` edge field, via each node type's `outgoing_ids()` — see the `node_visuals/` note below)
- [x] Create nodes from a context menu. (right-click-canvas AND drag-release-from-a-pin both open the same searchable, arrow-key-navigable popup, filtered to compatible types when opened from a pin — see notes below)
- [x] Delete nodes. (`GraphEdit.delete_nodes_request`)
- [x] Move nodes. (`GraphElement.dragged(from, to)`)
- [x] Connect nodes. (drag-to-connect; a brand new target/source node from a pin-drag is created and connected in one step)
- [x] Disconnect nodes. (`GraphEdit.disconnection_request`)
- [x] Prevent invalid connections. (`GraphEdit.connection_request` + `DialogueGraphEdit._is_node_hover_valid()` reject live, mid-drag — see Design Reference and notes below)
- [x] Edit selected node properties. (`node_selected` → `EditorInterface.edit_resource(node)`, reuses the native Inspector rather than building a custom property UI)
- [x] Persist node positions. (a dragged node's `editor_position` is committed via `EditorUndoRedoManager`, then written to disk in `_apply_changes()` — see notes below)
- [x] Support zoom/pan. (native `GraphEdit` behavior, no work needed)
- [x] Support Undo/Redo. (every structural edit — move, create, delete, connect, disconnect — commits through one atomic helper, so all of them are uniformly Ctrl+Z/Ctrl+Y-able, not just moves)
- [x] Highlight `Entry`. (title prefixed with `▶`)
- [x] Visually distinguish node types. (Blueprint-style color-coded titlebars, one color per type via each `node_visuals/*.gd`'s `color()`)
- [x] Display validation errors. (`ConversationGraph::validate()`'s messages are matched to nodes by id and shown as an error/warning count on the node, full text in its tooltip)

**Complete**, with one known, deliberately scoped gap: `Condition`/`RandomNode` still render a single generic output slot, so drag-connect is rejected for them (`can_connect_to` returns `false`) and `true_id`/`false_id`/`branches` stay Inspector-edited — the Design Reference's labeled/colored `True`/`False` pins need a multi-row `GraphNode` body, which wasn't built. Both nodes' outgoing edges still render correctly regardless of how they were set. Node/connection creation, deletion, and property editing are otherwise all in place.

### Notes from building the read-only visualizer

- **All GDExtension resource classes needed `#[class(tool, ...)]`** to be usable from any editor-context code (`EditorScript`, and critically `EditorPlugin`) at all — without it, every property/method access silently returns a non-functional "placeholder instance." This is a real gdext requirement, not a caching issue (confirmed against gdext's own docs), and was a prerequisite fix applied to every node type and `ConversationGraph` before this phase could start.
- **Main-screen placement, not a bottom panel** — a bottom panel felt cramped for something that wants real canvas space; `EditorInterface.get_editor_main_screen()` (a `VBoxContainer`) plus `_has_main_screen()`/`_get_plugin_name()`/`_get_plugin_icon()` gives a proper top-level tab instead. That container silently gives children `0` height unless the child's `size_flags_vertical` is set to `SIZE_EXPAND_FILL` *before* `add_child()` — setting it in the child's own `_ready()` wasn't reliably enough; a `custom_minimum_size` floor was added too as a forcing fallback.
- **`GraphEdit.get_children()` includes GraphEdit's own internal nodes** (its `connections_layer`, etc.), not just the `GraphNode`s we add — blindly `queue_free()`-ing every child on rebuild destroyed GraphEdit's own internals ("connections_layer is missing" errors on every redraw). Fixed by filtering to `if child is GraphNode`.
- **`queue_free()` is deferred** — rebuilding immediately after (e.g. switching to a different `ConversationGraph` quickly) could leave an old same-named node alive long enough that Godot auto-renamed the new one to avoid a collision, silently breaking `connect_node()` for that node. Fixed by using immediate `free()` for our own cleanup instead.
- **A freshly-created `GraphNode` doesn't auto-shrink to its content** — `reset_size()` is needed after adding content, otherwise nodes render far larger than their actual text needs.
- **A one-time layout bake, then the auto-layout code was deleted** (see the Design Reference section above for why: persist positions, don't auto-layout on load). A DFS assigning the longest acyclic path length from `Entry` (skipping edges back to an *ancestor* on the current path — a genuine cycle, e.g. via `Restart` — so a loop can never push itself rightward without bound, while still letting a *longer independent* path push a shared convergence point further right, with all `End` nodes forced to one shared trailing layer) was built, then run once headlessly (reusing real `GraphNode`/font sizing inside a live `SceneTree`, not guessed pixel values) against every existing test graph in `dev/dialogue_data/`, writing the computed positions into each node's `editor_position` and saving. With every graph now holding real positions, the algorithm itself was removed from `graph_editor.gd` — it now simply reads `editor_position` directly, matching the persist-positions model above. Any brand new, never-positioned node will just start at `Vector2.ZERO` until Phase 12's node-creation/move-persistence work gives it a real one.
- **Position persistence goes through `EditorUndoRedoManager`, not an immediate save on every drag.** The first instinct (call `ResourceSaver.save()` directly inside the `dragged` signal handler) was wrong — it bypasses Godot's normal edit/save flow entirely, auto-writing to disk on every micro-movement with no undo and no relationship to Ctrl+S. The correct hook is `EditorPlugin._apply_changes()`, which Godot calls "when the editor is about to save the project, switch to another tab, etc." — i.e. it's what Ctrl+S actually triggers. So: `dragged` commits a real action via `plugin.get_undo_redo()` (`add_do_property`/`add_undo_property` on the node's `editor_position`), which marks things dirty and gives Ctrl+Z for free; `_apply_changes()` is where the actual `ResourceSaver.save()` call lives, firing only when the editor's own save flow runs it.
- **Per-node-type editor logic moved into `node_visuals/`, one file per type, mirroring `dialogue-flow-rust/src/resources/`.** `graph_editor.gd`'s `_describe()`/`_outgoing_ids()`/`_configure_slots()` were growing `if node is X` chains that would only get worse with color-coding and labeled pins ahead. Replaced with a `NodeVisual` base (`describe()`/`outgoing_ids()`/`configure_slots()`) and one subclass per node type in `node_visuals/`, looked up by class name from a `Dictionary` in `graph_editor.gd` instead of branching. One real GDScript gotcha hit along the way: an overriding `static func` must match its parent's declared parameter *types* exactly — `static func describe(node: SpeechNode)` overriding a `describe(node: Resource)` base is a compile error, not a narrowing override; every visual file's functions are typed `Resource` like the base, with the specific fields still accessed dynamically at runtime.

### Notes from building interactive editing

- **Connection legality is data, not `graph_editor.gd` branching.** Each `node_visuals/*.gd` exposes `can_connect_to(node, target)`, `connection_patch(node, target)` / `disconnection_patch(node, target_id)` (returning `{property, value}` for the field to change, or `{}` for "not applicable"), and `can_be_source()`. `graph_editor.gd` just calls these — it doesn't know that `SpeechNode` branches between `response_ids` (append) vs `fallback_id` depending on the target type, or that `Condition`/`Random` reject drag-connect. This mirrors the same `node_visuals/` split from the read-only phase.
- **Pin-drag-to-empty-space reuses the same search popup as right-click**, via `GraphEdit.connection_to_empty`/`connection_from_empty`, filtered to types `can_connect_to`-compatible with the dragged pin (and, for a drag started at an *input* pin, filtered further by `can_be_source()` — a new node needs an output at all to feed into it). Picking a type creates the node and wires the connection as one undo step.
- **Live invalid-connection rejection needs a `GraphEdit` subclass, not a signal** — `_is_node_hover_valid()` is a virtual method GraphEdit calls while a connection drag is in progress, not something `connect()` can hook. `dialogue_graph_edit.gd` is a small subclass just for this, delegating back to `graph_editor.gd`'s `is_connection_valid()`.
- **Every structural edit funnels through one atomic do/undo helper** (`_commit_multi_change` / `_apply_entries_and_rebuild` in `graph_editor.gd`) rather than one `add_do_property`/`add_do_method` pair per field. With several `add_do_*`/`add_undo_*` entries in one `EditorUndoRedoManager` action, the order they actually run in on undo isn't documented well enough to bet a correct rebuild on — so each side (do/undo) is a single method call that applies every `[object, property, value]` entry and rebuilds once, sidestepping the ordering question entirely.
- **That rebuild has to be deferred.** It immediately `free()`s old `GraphNode`s (see the read-only-phase notes above on why immediate over `queue_free()`), but it often runs synchronously from inside a signal that `GraphEdit` or the dragged `GraphNode` itself is still emitting (`dragged`, `connection_to_empty`) — Godot refuses to free a node while it (or an ancestor) is mid-signal-dispatch ("Object is locked and can't be freed"). `call_deferred("_rebuild")` runs it after that call stack unwinds; the actual data mutation stays synchronous, only the visual rebuild is delayed a frame.
- **A `Label` added as a child of `GraphEdit` inherits its pan/zoom transform** — an "empty state" placeholder needs to stay docked to the viewport regardless of scroll/zoom, so it has to live in a plain sibling `Control` overlaying `GraphEdit`, not inside it.
- **`_ready()` needs to call `_rebuild()` once itself.** Without it, `current_graph` and the empty-state label's text both stay at their just-constructed defaults (`null` / `""`) until the first `load_graph()`/close — meaning the "no graph open" placeholder was invisible (empty text, not just hidden) on a fresh plugin load, only ever appearing after a graph had been opened and closed at least once.

## Milestone

- [x] A conversation can be created from scratch without manually editing raw resources.

Reached — New Graph, node creation (search popup), drag-to-connect, Inspector-based property editing, and Save cover the full authoring loop now.

---

# Pre-v1 Architecture Stress Test

Before going deeper into Phase 13, the architecture was deliberately
stress-tested against eleven external Godot/GDExtension projects chosen
for overlapping engineering concerns — not to copy their scope, but to
borrow their accumulated lessons before freezing decisions for v1.
Primary references (deep investigation, including issues/PRs/history):
Dialogic, Dialogue Manager, Godot Orchestrator, Questify, LimboAI.
Specialist references (lighter treatment, one lesson each): Godot State
Charts, Yarn Spinner, Dialogue Nodes, Sprouty Dialogs, Beehave. ("Quest
Weaver" had no findable/credible repository and was dropped.)

## Verdict

No fundamental flaw was found in the graph model, runtime architecture,
node identity, serialization format, or editor/Undo-Redo design. Several
early decisions were independently validated by contrast with mature
projects that hit the same problem first:

- **Authored Resources stay read-only at runtime; all mutable state lives
  on `DialogueController`** (`state`, `current_id`, `running`) — confirmed
  by inspection: `enter()` never calls a mutating accessor on any node.
  LimboAI's `BTPlayer.instantiate()` and Questify's `instantiate()` +
  `duplicate(true)`-plus-manual-reference-rewrite both exist specifically
  to retrofit this same guarantee after choosing to store mutable state
  on their authored Resources in the first place. Dialogic's runtime, by
  contrast, aliases *and writes into* its authored event objects
  directly, and only gets away with it because its game handler is a
  global singleton. **Frozen.**
- **Every structural editor edit (move/create/delete/connect/disconnect)
  funnels through one atomic `_commit_multi_change` do/undo path.** Godot
  Orchestrator has no equivalent — its own
  [issue #58](https://github.com/CraterCrash/godot-orchestrator/issues/58)
  (open since March 2024) reports 7 of 13 graph operations that can't be
  undone, with Ctrl+Z instead silently reverting unrelated scene edits.
  **Frozen** — every future Phase 13 feature must keep going through this
  same path, never a shortcut.
- **Author-typed, stable `id: GString`** avoids problems others had to
  retrofit: Dialogue Manager's line-number ids needed a bolted-on
  `static_id` after users hit reference instability; Godot Orchestrator's
  own maintainer flags its monotonic, never-reused int ids as an
  imperfect strategy in a code comment. **Frozen.**
- **Structured errors-vs-warnings validation, surfaced per-node** — ahead
  of every reference checked. Dialogic has no static validation at all,
  four years into its 2.0 rewrite; Questify only hard-gates
  exactly-one-Start/-End at save time.
- **String-id-addressed edges** (vs. object-reference edges, e.g.
  Questify's `QuestEdge.from`/`to`) are more source-control/merge-friendly
  — confirmed by direct contrast.

## Concrete follow-ups folded into the phases below

- Phase 13: when duplicate/copy-paste is implemented, the copied node's
  `id` must be cleared and regenerated via the existing
  `_generate_unique_id()` — never keep the source's id (Questify's
  confirmed correct pattern).
- Phase 13: an in-editor conversation previewer is worth adding —
  independently converged on by two unrelated peer projects (Dialogue
  Nodes, Sprouty Dialogs), and cheap given `DialogueController` is
  already signal-driven and decoupled from `DialogueUI`.
- Phase 15: add `cargo test` unit coverage for `graph::validate()` and
  `DialogueController::enter()`'s core branches. This logic is pure Rust
  with no GDExtension dependency to exercise it — LimboAI's ~38-file
  native test suite is proof this is cheap, and this project's own
  history (the Phase 6/11 illegal `fallback_id` bug) shows manual testing
  alone catches things late.
- Phase 16: document (and eventually test against) the actual supported
  Godot version range for the built binary — currently implicit. Budget
  real time for packaging generally: mature references (Orchestrator,
  LimboAI) ship 10-20+ binary artifacts across multiple platforms via
  dedicated per-platform CI, well beyond "build the `.so` and zip it."
- Phase 14 (deferred, not a v1 requirement): reserve API shape for a
  future `DialogueController` state save/load pair. Not needed for v1 (no
  save-game feature is in scope), but Questify shipped two real bugs
  ([issue #11](https://github.com/TheWalruzz/godot-questify/issues/11),
  [PR #12](https://github.com/TheWalruzz/godot-questify/pull/12)) from
  exactly this kind of state silently dropping across a serialize/
  deserialize cycle it hadn't planned for.

## What was deliberately NOT adopted

Expression/conditional-language engines (Dialogic, Dialogue Manager),
live reflection into arbitrary external game objects (Dialogue Manager),
dynamic node-type discovery/registries (Orchestrator), custom binary
serialization formats (Orchestrator), and any VM/bytecode compilation
step (Yarn Spinner) were all considered and rejected — each solves a
problem DialogueFlow's smaller, fixed-vocabulary graph model doesn't
have.

---

# Phase 13 — Editor Quality of Life

## Tasks

- [x] Node search/create menu. (built in Phase 12 — right-click and drag-release-from-a-pin both open the same searchable, arrow-key-navigable popup)
- [x] Duplicate nodes. (Ctrl+D/Ctrl+W, Blueprint-style; `NodeVisual.remap_ids()` — one override per node type — rewrites each duplicate's own edge fields via an old-id→new-id map, clearing anything that pointed outside the duplicated selection rather than leaving it dangling or silently reconnected to the original graph; duplicates get a freshly generated `id` via `_generate_unique_id()`, per the Pre-v1 Architecture Stress Test's fresh-id-on-duplicate finding, and are left selected afterward)
- [x] Copy/paste. (Ctrl+C/Ctrl+V; shares `_clone_and_commit()` with duplication — copy snapshots selected nodes via `duplicate(true)` into an in-memory clipboard buffer at copy time, decoupled from later edits to the originals; paste re-clones that buffer fresh each time, so pasting repeatedly never shares sub-resources across pastes, and drops the group at the mouse position, keeping the copied nodes' relative layout by re-centering on their original centroid)
- [ ] In-editor conversation preview/playtest. (not originally on this list — added after the Pre-v1 Architecture Stress Test above; cheap given `DialogueController` is already signal-driven and decoupled from `DialogueUI`)
- [x] Multi-select. (native `GraphEdit` behavior — ctrl/shift-click and rubber-band select all work with no extra code, same as Phase 12's zoom/pan; confirmed working correctly with group duplicate and group copy/paste)
- [ ] Delete selected graph region. (likely already covered by the `delete_nodes_request` wiring from Phase 12, which already receives every currently-selected node's name — worth a quick confirmation pass rather than new work)
- [ ] Automatic unique IDs.
- [ ] Search/rename speakers.
- [ ] Search dialogue text.
- [ ] Jump to node by ID.
- [ ] Highlight invalid nodes.
- [ ] Highlight unreachable nodes.
- [ ] Reroute nodes. (double-click a wire to insert one, already connected on both sides — see Phase 12's Design Reference)
- [ ] Optional comments/groups. (Blueprint-style resizable, labeled comment boxes around a selection)
- [ ] Confirmation for destructive actions.
- [ ] Sensible default node sizes.
- [ ] Useful tooltips/documentation.
- [ ] Straighten Connections action. (align connected nodes so a wire — or every wire in a selection — becomes a straight horizontal line; see Phase 12's Design Reference)
- [ ] Align/Distribute selected nodes. (Top/Middle/Bottom/Left/Center/Right align, horizontal/vertical distribute — see Phase 12's Design Reference)

### Notes from building node duplication

- **`Array.map()` always returns a plain untyped `Array`, even when every
  element it produces is a `String`.** Assigning its result directly to a
  typed `Array[String]` var (`pending_selection_ids`) fails at runtime
  with "Trying to assign an array of type 'Array' to a variable of type
  'Array[String]'" — not a parse-time error, so it only surfaced when
  actually running the editor. Fixed by building the typed array with an
  explicit `for` loop instead, matching how every other typed array in
  this codebase is already built.
- **A one-line indentation slip silently breaks intent without any
  error at all.** The post-rebuild reselection loop's
  `pending_selection_ids = []` reset landed one indentation level too
  deep (inside the `for gnode in ...` loop instead of after it), so it
  cleared the pending list on the very first child checked — before any
  actual `GraphNode` was ever reached. Duplication itself still worked
  correctly; only the "leave the new copies selected" nicety silently
  never fired. Caught by re-reading the applied diff line by line rather
  than by any error message — worth remembering that a misplaced-by-one
  indent in GDScript is not something `--check-only` (or any parser) will
  ever catch, since it's still entirely valid syntax.
- `duplicate(true)` (deep copy, not the default shallow `duplicate()`)
  is required specifically for `RandomNode`, whose `branches` are
  themselves sub-resources (`RandomBranch`) — a shallow duplicate would
  leave the copy sharing the exact same branch instances as the original.

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

## Observability

The point of this module is to let external systems *react* to a
conversation, which means signals need to carry enough identifying data
to do that, not just announce "something happened":

- [ ] `dialogue_finished` should identify which `End` node was reached
      (currently it carries no payload — see
      `DialogueController::enter`/Phase 3 in `dialogue-flow-rust/src/runtime/mod.rs`).
      Two different `End`s in the same graph are indistinguishable to a
      listener today.
- [ ] `node_entered`/`node_exited` should carry the entered/exited node's
      `id`, so an external system can trace the exact path taken through
      a conversation, not just its start/end.
- [ ] Revisit whether `speech_changed`/`responses_changed` should also
      carry the current node's `id`, for the same reason.

"Trigger"-style outputs (UEFN Dialog Device comparison) are already
covered by the planned `Event` node (Phase 7) — a `StringName` identifier
plus optional payload, surfaced through `event_emitted`. No new node type
is needed for this; it just needs Phase 7 to actually land with a real
payload, not a stub.

Confirmed during Phase 9: the `dialogue_finished(end_id)` gap is a
deliberate stay-in-order decision, not an oversight — asked directly
whether to pull it forward, and the choice was to leave it here rather
than jump ahead.

## State Persistence (deferred)

- [ ] Reserve API shape for a future `DialogueController` state
      save/load pair (e.g. `get_state()`/`set_state()` around the
      internal `state` map). Not a v1 requirement — no save-game feature
      is in scope — but flagged by the Pre-v1 Architecture Stress Test:
      Questify shipped two real bugs from state silently dropping across
      a serialize/deserialize cycle it hadn't planned for
      ([#11](https://github.com/TheWalruzz/godot-questify/issues/11),
      [PR #12](https://github.com/TheWalruzz/godot-questify/pull/12)).
      Cheap to leave room for now, easy to get wrong silently later.

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

- [ ] Automated `cargo test` unit coverage for `graph::validate()` and
      `DialogueController::enter()`'s core branches. Flagged HIGH
      priority by the Pre-v1 Architecture Stress Test above: this logic
      is pure Rust with no GDExtension dependency to exercise it, so it's
      cheap to test directly rather than relying only on manual
      `.tres`-graph sweeps (which the project's own history shows caught
      at least one real bug — the Phase 6/11 illegal `fallback_id` — only
      late).
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

- [ ] Document the supported Godot version range for the built binary
      (a compatibility floor, relying on GDExtension ABI stability —
      not a separate binary per Godot minor version; see the Pre-v1
      Architecture Stress Test above, informed by LimboAI's and
      Orchestrator's `.gdextension` compatibility declarations).
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
