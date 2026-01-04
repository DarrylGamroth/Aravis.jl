# Phase 0: Prep Status

- [x] Target Linux only for initial implementation.
- [x] API maps directly to Aravis with idiomatic Julia naming and BGAPI2.jl-style modules.
- [x] Plan to use GLib_jll for GObject/GLib symbols.
- [ ] Confirm Aravis_jll provides libaravis and headers (or decide to vendor headers).
- [ ] Identify minimal public headers for V1 bindings.
- [ ] Record exact GLib/GObject function list needed for ref/unref and GError handling.
