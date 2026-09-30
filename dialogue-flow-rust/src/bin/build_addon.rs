// Builds the dialogue-flow-rust GDExtension and copies the resulting
// library into addons/dialogue_flow/bin/ inside the Godot project, so the
// addon is self-contained -- nothing outside addons/dialogue_flow/ is
// needed to load it, which is what an Asset Library package actually
// ships. Plain Rust (std::process::Command + std::fs) rather than a shell
// script so it runs the same way on Windows/Linux/macOS with no per-OS
// script and no extra tooling beyond cargo itself.
//
// Usage: cargo build-addon [debug|release|all]   (default: release)
//
// `all` builds and copies both profiles in one invocation -- needed
// because the Godot editor itself is a debug build and so always loads
// the `debug` library (per dialogue-flow.gdextension), while a release
// export of a game loads `release`; rebuilding only one leaves the other
// silently stale.

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

fn main() {
    let arg = env::args().nth(1).unwrap_or_else(|| "release".to_string());
    let profiles: &[&str] = match arg.as_str() {
        "debug" => &["debug"],
        "release" => &["release"],
        "all" => &["debug", "release"],
        _ => {
            eprintln!("Usage: cargo build-addon [debug|release|all]");
            std::process::exit(1);
        }
    };

    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));

    // Runtime lookup rather than env!("CARGO"): cargo also sets this env var
    // for the process it launches via `cargo run`, and unlike the compile-time
    // macro it can't go stale if this binary was compiled once and reused with
    // a different cargo install later.
    let cargo = env::var("CARGO").unwrap_or_else(|_| "cargo".to_string());

    for profile in profiles {
        build_one(profile, &manifest_dir, &cargo);
    }
}

fn build_one(profile: &str, manifest_dir: &Path, cargo: &str) {
    let mut cargo_args = vec!["build", "--lib"];
    if profile == "release" {
        cargo_args.push("--release");
    }
    let status = Command::new(cargo)
        .args(&cargo_args)
        .current_dir(manifest_dir)
        .status()
        .expect("failed to run `cargo build` for the GDExtension library");
    if !status.success() {
        std::process::exit(status.code().unwrap_or(1));
    }

    let target_dir = manifest_dir.join("target").join(profile);
    let addon_bin = manifest_dir
        .join("..")
        .join("dialogue-flow-godot")
        .join("addons")
        .join("dialogue_flow")
        .join("bin");

    let (src_name, platform_dir, dest_name): (String, &str, String) =
        if cfg!(target_os = "linux") {
            (
                "libdialogue_flow.so".to_string(),
                "linux",
                format!("libdialogue_flow.{profile}.so"),
            )
        } else if cfg!(target_os = "macos") {
            (
                "libdialogue_flow.dylib".to_string(),
                "macos",
                format!("libdialogue_flow.{profile}.dylib"),
            )
        } else if cfg!(target_os = "windows") {
            (
                "dialogue_flow.dll".to_string(),
                "windows",
                format!("dialogue_flow.{profile}.dll"),
            )
        } else {
            eprintln!("Unsupported OS -- add a branch for it here.");
            std::process::exit(1);
        };

    let src = target_dir.join(&src_name);
    let dest_dir = addon_bin.join(platform_dir);
    fs::create_dir_all(&dest_dir).expect("failed to create addons/dialogue_flow/bin/<platform>");
    let dest = dest_dir.join(&dest_name);
    fs::copy(&src, &dest).unwrap_or_else(|e| {
        panic!(
            "failed to copy {} -> {}: {e}",
            src.display(),
            dest.display()
        )
    });
    println!("Copied {} -> {}", src.display(), dest.display());
}
