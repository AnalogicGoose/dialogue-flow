//! Runtime execution: traverses a conversation graph and drives the
//! Godot-facing `DialogueController` node.
//!
//! Depends on [`graph`](crate::graph) and [`resources`](crate::resources)
//! but knows nothing about presentation; the dialogue UI only talks to this
//! module through signals and public methods (see Phase 3/4 of the roadmap).
