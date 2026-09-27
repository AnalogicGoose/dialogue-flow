# Graph Specification

Phase 1 deliverable: defines exactly how a `DialogueFlow` conversation
graph behaves, so Phase 2+ can implement it without inventing behavior
mid-coding. This is a behavioral spec, not an API — Rust/Godot types come
in Phase 2.

---

## Node Identity

- Every node has a **stable, unique, author-assigned string ID**, unique
  within its graph. IDs are how edges, Responses, and Restart/Entry
  references point at nodes — never by array index or object identity.
- IDs are assigned automatically when a node is created and are editable
  by the author (needed for the future graph editor's "jump to node by
  ID" and for hand-editing `.tres` files).
- IDs are graph-local. Nothing outside a single conversation graph
  resource resolves them.

## Edges

There is no single generic "edge" type shared by all nodes. Each node
type declares its own outgoing shape, because different node types
branch differently (a `Condition` always has exactly two outgoing paths,
a `Random` has a variable number, an `End` has none). An edge is simply a
target node ID stored on the source node.

Incoming edges are never stored on the target. Any node may be the target
of any number of edges from any number of sources — this is what makes
branch convergence free (locked decision, no `MergeNode` needed).

## Node Vocabulary & Connection Rules

| Node        | Outgoing shape                                   | Pauses traversal? |
|-------------|---------------------------------------------------|--------------------|
| `Entry`     | 1 edge → any node except `Entry`/`Response`        | No |
| `Speech`    | **either** N `Response` children **or** 1 fallback edge (mutually exclusive) | Yes, if it has ≥1 `Response` |
| `Response`  | 1 edge → any node except `Entry`/`Response`        | No (resumes traversal once chosen) |
| `Event`     | 1 edge → any node except `Entry`/`Response`        | No |
| `Condition` | 2 edges (`true`, `false`) → any node except `Entry`/`Response` | No |
| `Random`    | N weighted edges → any node except `Entry`/`Response` | No |
| `WaitForEvent` | 1 edge → any node except `Entry`/`Response`     | Yes, until the matching event arrives |
| `Reroute`   | 1 edge → any node except `Entry`/`Response` (chaining allowed) | No |
| `Restart`   | none stored — fixed runtime behavior: jump to the graph's `Entry` | No |
| `End`       | none — terminal                                    | Yes (conversation ends) |

Connection legality, stated once instead of per-row: **no edge may ever
target `Entry` or a `Response`.** `Entry` is only reached by starting the
graph or via `Restart`. A `Response` is only ever reached as a child of
its owning `Speech`, never addressed by a generic edge.

A `Speech` node with zero `Response` children and no fallback edge is a
dead end, and dead ends are only legal on `End` (see below).

## Entry Semantics

- A graph has **exactly one** `Entry` node. Zero or more than one is an
  editor validation error, not a runtime fallback choice.
- Starting a conversation always begins traversal at `Entry`.

## Dead Ends

Only `End` may have no outgoing edge. Any other node type missing a
required target (an unset fallback edge, an unset `Condition` branch, an
empty `Random` branch list) is a **validation error** — "invalid graphs
should fail clearly" (locked design principle) means we never silently
stop traversal on a node that wasn't explicitly designed to stop it.

## Multiple Incoming Edges

Unrestricted. Any node may be targeted by any number of edges from any
number of source nodes and node types. The runtime makes no
parent/ownership assumption about how a node was reached — it just
executes the node it's currently on. This is the entire mechanism behind
branch convergence; no additional node type or bookkeeping is needed.

## Cycles & Loop Safety

Cycles are legal and expected — `Restart` exists specifically to create
one, and `Reroute` chains or `Condition`/`Random` branches can also loop
back on themselves.

The risk is a cycle made entirely of nodes that don't pause traversal
(`Speech` without responses, `Event`, `Condition`, `Random`, `Reroute`,
a `Restart` that loops immediately back through automatic nodes to
itself). Such a cycle would spin forever within a single synchronous
traversal step. Two layers handle this, at two different phases:

- **Editor validation** (Phase 11): statically warn when a cycle contains
  no pausing node (`Speech` with responses, or `WaitForEvent`).
- **Runtime guard** (Phase 3): cap the number of automatic node
  transitions taken in one traversal step; exceeding it is a runtime
  error, not a hang.

Both exist because static analysis alone can't catch every case (e.g. a
`Condition` whose branch depends on state only known at runtime).

## Termination

- Reaching `End` finishes the conversation successfully and emits
  `dialogue_finished`.
- Calling `stop()`/`cancel()` externally ends it early and emits
  `dialogue_cancelled`.
- There is no implicit termination from "running out of graph" — any
  path that isn't `End` is a validation error, never a silent stop.

## Validation Errors vs. Runtime Errors

- **Validation error** — detectable from the graph resource alone,
  without running it: missing/duplicate `Entry`, duplicate node ID,
  dangling target ID, illegal connection (see legality rule above),
  `Speech` with both responses and a fallback edge (or neither),
  unreachable node, a cycle with no pausing node. These surface through
  the Phase 11 validation API and the Phase 12 graph editor, ideally
  before the conversation ever runs.
- **Runtime error** — only detectable while executing with live state: a
  `Condition` referencing a variable that isn't set, an automatic-step
  cap actually being hit despite passing static checks, a malformed
  external event payload. These are reported through a runtime error
  signal and traversal stops safely — never a panic.

Rule of thumb: if the resource alone answers the question, it's a
validation error; if the answer depends on runtime state or timing, it's
a runtime error.

## Traversal: Automatic vs. Paused

After entering a node that doesn't pause (`Event`, `Condition`,
`Random`, `Reroute`, a `Speech` with no responses, `Restart`, or a
`WaitForEvent` whose event just arrived), the runtime immediately
evaluates it and advances to its target in the same traversal step,
continuing until it reaches a node that pauses or reaches `End`. This
chain is what the Phase 3 automatic-step cap guards.

Pausing nodes are exactly: a `Speech` with ≥1 `Response` (waits for
`choose()`), and `WaitForEvent` before its event arrives (waits for
`receive_event()`). Nothing else pauses.

**Authoring note:** a fallback-only `Speech` (no responses) is invisible
to the player in practice — it fires `speech_changed` and immediately
falls through to whatever comes next in the same step, giving a UI no
frame to display it before it's overwritten or the conversation ends. Use
`fallback_id` only for back-to-back automatic beats you don't need read;
for any line the player should actually see before it advances (even one
with nothing meaningful to choose), give it a single `Response` — e.g.
`"Continue..."` — instead of a `fallback_id`. This is deliberate, not a
bug: v1 has no separate "advance on click" mechanism, so a `Response` is
how you get a readable pause.

## Worked Example

```text
Entry
  |
  v
Speech("Guard: Halt.")
  |
  +--> Response("Let me through") --> Condition(has_pass)
  |                                        |         |
  +--> Response("I have a pass") --------> true      false
                                            |           |
                                            v           v
                                     Speech("Enter.")  Event("alarm")
                                            |                |
                                            v                v
                                           End         Speech("Leave.")
                                                              |
                                                              v
                                                             End
```

This graph has one `Entry`, a pausing `Speech` with two `Response`
children, a `Condition` with both branches populated, and two distinct
paths reaching `End` — exercising branching, convergence-free divergent
paths, an outgoing event, and clean termination.
