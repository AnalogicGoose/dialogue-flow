//! Godot-facing `Resource` types used to author conversation content.
//!
//! Wraps the [`graph`](crate::graph) model in `#[derive(GodotClass)]` types
//! so conversations can be edited in the Inspector and saved as `.tres`
//! files, without dialogue content living in Rust source.
