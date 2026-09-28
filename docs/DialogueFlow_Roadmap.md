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
