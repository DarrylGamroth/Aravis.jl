# Spec: Julia wrapper for Aravis (Aravis.jl)

## Purpose
- Provide a Julia wrapper around Aravis (GObject-based camera/stream library) using Aravis_jll (0.8.35 today), with a path to a future 0.9.1 update for GenTL producer support.
- Deliver two implementation plans: GObject Introspection via Gtk4.jl/GI.jl, and direct C API wrapping.

## Review: Aravis
- GObject-based library for GenICam cameras (GigE/USB3), with higher-level ArvCamera and lower-level ArvDevice/ArvGc APIs.
- GenTL support exists: searches GENICAM_GENTL{32/64}_PATH for *.cti.
- Thread-safety: objects are not thread-safe across threads; signal callbacks may be invoked from internal threads (notably stream callbacks).
- GObject Introspection support is generated via meson (g-ir-scanner) when introspection is enabled. It produces an Aravis namespace, symbol prefix arv_, and installs typelibs.

## Review: Gtk4.jl + GI.jl
- GI.jl generates Julia wrappers from GI metadata; it uses annotations to manage ownership, nullable args, arrays, and GError conversion to exceptions.
- Gtk4.jl’s generator scripts show the expected pipeline: add typelib search path, parse GIR, export consts/structs/methods/functions into src/gen/*.
- GI.jl expects the GI repository search path to include lib/girepository-1.0 for the relevant JLL.
- Known constraints: GI extraction runs on Linux; generated code can be imperfect and may require manual patches.

## Plan A: GObject Introspection via Gtk4.jl/GI.jl

### Goal
- Auto-generate thin wrappers for the Aravis namespace using GI metadata from Aravis_jll.

### Assumptions
- Aravis_jll ships Aravis-0.8.typelib and Aravis-0.8.gir in its artifact lib/girepository-1.0. If missing, JLL must be updated.

### Steps
1) Metadata validation
   - Verify Aravis_jll includes typelibs. If not, update Aravis_jll to install GI artifacts or provide a supplementary artifact.
2) Generator script
   - Add gen/gen_aravis.jl similar to Gtk4.jl scripts:
     - GI.prepend_search_path(Aravis_jll)
     - ns = GI.GINamespace("Aravis", "0.8")
     - GI.export_consts!/structs!/methods!/functions! into src/gen.
3) Package structure
   - src/Aravis.jl loads generated consts/structs/methods/functions, defines libaravis alias from Aravis_jll.
   - Provide minimal hand-written helpers (e.g., camera open/list devices, stream buffer helpers).
4) Manual patch layer
   - Patch allocations or ownership mismatches from GI output (e.g., buffers, arrays, callback closures).
   - Provide custom wrappers for high-frequency streaming APIs to reduce allocations.
5) Testing
   - Non-hardware tests: load namespace, create objects, call basic functions, check error handling.
   - Optional: exercise arv-fake-gv-camera via Aravis utilities if usable in CI.

### Deliverables
- Generated files in src/gen/*, top-level module with thin wrappers, and a small set of hand-written conveniences.

### Risks/Notes
- GI metadata quality may require manual patching.
- Thread-safety and callback threading are notable risk areas for Julia GC interaction.

## Plan B: Direct C API wrapping (ccall/Clang.jl)

### Goal
- Manually wrap the C API with predictable memory/ownership semantics and tailored performance.

### GLib/GObject and event loop considerations
- Aravis types are GObjects, so Plan B still needs a minimal GLib/GObject layer for ref/unref, properties, and errors.
- Signals and async callbacks are optional; if they are not supported, the wrapper can stay deterministic and avoid GLib main loop integration.
- Most functionality can be accessed without a GLib main loop by using polling-based APIs (e.g., stream_timeout_pop_buffer) and synchronous camera/device calls.
- If signals are enabled later, add a small GLib main loop wrapper (g_main_loop_* / g_main_context_iteration) and document threading constraints.

### Polled mode API checklist
- Device discovery and open (interfaces, camera list, open by ID).
- Camera configuration (features/properties via ArvDevice/ArvGc).
- Stream setup and buffer management (create stream, push buffers).
- Acquisition loop using stream_timeout_pop_buffer or try_pop_buffer.
- Buffer inspection and metadata access (timestamp, payload type).

### Steps
1) API surface definition
   - Start with core objects: ArvCamera, ArvDevice, ArvStream, ArvBuffer, ArvGc, plus utility functions (device enumeration, open camera).
2) Low-level bindings
    - Use Clang.jl to generate raw bindings from arv.h (or manual ccall for a smaller surface).
   - Expose enums/flags and C structs.
3) GObject integration
   - Implement Julia wrapper types around Ptr{GObject} with explicit ref/unref.
   - Map GError to Julia exceptions.
   - Provide finalizer and explicit close/unref semantics.
4) Higher-level API
   - Implement allocation-free hot path for streaming (buffer dequeue/queue).
   - Provide helpers for GenICam properties if needed.
5) Testing
   - Similar to Plan A; include validation of ownership/freeing patterns.

### Deliverables
- src/raw/*.jl (generated), src/Aravis.jl with wrapper types and safe API, plus a small stable high-level surface.

### Risks/Notes
- More manual effort and higher maintenance cost, but better control over performance and allocations.
- Requires careful mapping of ownership and thread-safety semantics.
- If signals are omitted, document the supported polled mode APIs and any gaps (e.g., no signal-based notifications).

## Versioning & GenTL considerations
- Current Aravis_jll (0.8.35) aligns with the Aravis-0.8 namespace and API.
- For GenTL enhancements and newer features, plan a JLL bump to 0.9.1 and re-run generation (Plan A) or refresh bindings (Plan B).
- Ensure GENICAM_GENTL{32/64}_PATH environment handling is documented in Julia wrapper.

## Suggested decision criteria
- If rapid coverage and lower initial effort is preferred: Plan A.
- If allocation control, stability across platforms, and customized high-performance streaming are priority: Plan B.
