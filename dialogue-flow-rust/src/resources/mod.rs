//! Godot-facing `Resource` types used to author conversation content.
//!
//! Wraps the [`graph`](crate::graph) model in `#[derive(GodotClass)]` types
//! so conversations can be edited in the Inspector and saved as `.tres`
//! files, without dialogue content living in Rust source.
//!
//! Every node type is a sibling `Resource` subclass — gdext only allows
//! `#[class(base = ...)]` to name an engine class, not another custom
//! class, so there is no shared Rust base type. [`ConversationGraph`]
//! stores nodes as `Array<Gd<Resource>>` and downcasts by dynamic type
//! (`Gd::try_cast`) where a specific node kind is needed.

mod end;
mod entry;
mod graph;
mod response;
mod speech;

pub use end::EndNode;
pub use entry::EntryNode;
pub use graph::ConversationGraph;
pub use response::ResponseNode;
pub use speech::SpeechNode;
