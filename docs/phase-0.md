# Phase 0: Prep Status

- [x] Target Linux only for initial implementation.
- [x] API maps directly to Aravis with idiomatic Julia naming and BGAPI2.jl-style modules.
- [x] Plan to use GLib_jll for GObject/GLib symbols.
- [x] Confirm Aravis_jll provides libaravis and headers (or decide to vendor headers).
  - Headers are under `Aravis_jll.artifact_dir/include/aravis-0.8`.
- [x] Identify minimal public headers for V1 bindings.
  - Use `arv.h` as the umbrella header for generation; it pulls in all public headers.
  - V1 focus headers: `arvbuffer.h`, `arvstream.h`, `arvcamera.h`, `arvdevice.h`,
    `arvinterface.h`, `arvsystem.h`, `arvgc.h`, `arvgcnode.h`, `arvgcboolean.h`,
    `arvgcinteger.h`, `arvgcfloat.h`, `arvgcstring.h`, `arvgccommand.h`,
    `arvgcenumeration.h`, `arvgcenumentry.h`.
- [x] Record exact GLib/GObject function list needed for ref/unref and GError handling.
  - g_object_ref, g_object_unref, g_object_get, g_object_set
  - g_error_free, g_clear_error, g_free, g_strfreev
