//! GDExtension entry point for DialogueFlow.
//!
//! See [`graph`], [`resources`], and [`runtime`] for the module split
//! between graph data, Godot-facing authoring resources, and execution.

use godot::prelude::*;

mod graph;
mod resources;
mod runtime;

struct DialogueFlow;

#[gdextension]
unsafe impl ExtensionLibrary for DialogueFlow {}
