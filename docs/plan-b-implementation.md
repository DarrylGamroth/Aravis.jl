# Plan B Implementation Plan (Direct C API Wrapping)

## Goals
- Zero allocations in the acquisition hot path (buffer pool + polling).
- Explicit ownership and predictable lifetimes for all Aravis objects.
- Minimal GLib/GObject surface, no signals or async callbacks initially.
- Parity with your BGAPI2.jl patterns for buffers and polling.
- Linux-only initial target.

## Scope
- Wrap core Aravis objects: ArvCamera, ArvDevice, ArvStream, ArvBuffer, ArvGc.
- Support synchronous/polled acquisition using stream_timeout_pop_buffer / try_pop_buffer.
- API maps directly to Aravis, using idiomatic Julia naming and module namespaces modeled after BGAPI2.jl.
- Node access mirrors BGAPI2.jl patterns.
- Defer signals, GLib main loop, and async callbacks.

## Phase 0: Prep
- Confirm Aravis_jll provides libaravis and headers (or plan to vendor headers).
- Identify required C headers and minimal public API surface.
- Record required GLib/GObject functions for ref/unref and GError handling.
- Lock target to Linux for initial implementation.

## Phase 1: Low-level bindings
- Generate raw C bindings (Clang.jl or manual ccall) for:
  - aravis core API (camera/device/stream/buffer/gc).
  - minimal GLib/GObject: g_object_ref, g_object_unref, g_object_get, g_object_set, g_error_free.
- Keep raw bindings in `src/LibAravis.jl`.
- Prefer `GLib_jll` as the source for GLib/GObject symbols.

## V1 binding list (C symbols to cover)
### System and interface enumeration
- arv_update_device_list, arv_get_n_devices, arv_get_device_id, arv_get_device_vendor,
  arv_get_device_model, arv_get_device_serial_nbr, arv_get_device_protocol,
  arv_open_device, arv_shutdown.
- arv_get_n_interfaces, arv_get_interface_id, arv_get_interface_protocol,
  arv_get_interface, arv_get_interface_by_id, arv_enable_interface,
  arv_disable_interface, arv_select_interface, arv_set_interface_flags.
- arv_interface_update_device_list, arv_interface_get_n_devices,
  arv_interface_get_device_id, arv_interface_get_device_vendor,
  arv_interface_get_device_model, arv_interface_get_device_serial_nbr,
  arv_interface_get_device_protocol, arv_interface_open_device.

### Camera
- arv_camera_new, arv_camera_new_with_device, arv_camera_get_device,
  arv_camera_create_stream (callback unused in V1), arv_camera_start_acquisition,
  arv_camera_stop_acquisition, arv_camera_abort_acquisition, arv_camera_acquisition.
- Common configuration: region, binning, pixel format, frame rate, exposure, gain,
  trigger, payload size, component selection, and feature getters/setters.

### Device
- arv_device_create_stream, arv_device_start_acquisition, arv_device_stop_acquisition.
- Feature access: arv_device_get_feature, arv_device_get_feature_access_mode,
  arv_device_get_feature_representation, arv_device_is_feature_available,
  arv_device_is_feature_implemented.
- Typed feature I/O: arv_device_set/get_boolean_feature_value,
  arv_device_set/get_integer_feature_value (+ bounds/inc),
  arv_device_set/get_float_feature_value (+ bounds/inc),
  arv_device_set/get_string_feature_value, arv_device_execute_command,
  arv_device_set/get_register_feature_value, arv_device_dup_register_feature_value.
- GenICam: arv_device_get_genicam, arv_device_get_genicam_xml,
  arv_device_create_chunk_parser (optional V1).

### Stream
- arv_stream_push_buffer, arv_stream_pop_buffer, arv_stream_try_pop_buffer,
  arv_stream_timeout_pop_buffer, arv_stream_start_acquisition, arv_stream_stop_acquisition.
- arv_stream_get_statistics, arv_stream_get_n_owned_buffers.
- arv_stream_set_emit_signals (set false), arv_stream_get_emit_signals.

### Buffer
- arv_buffer_new_allocate, arv_buffer_new, arv_buffer_new_full.
- arv_buffer_get_status, arv_buffer_get_payload_type,
  arv_buffer_get_timestamp, arv_buffer_get_frame_id, arv_buffer_get_data.
- Image helpers: arv_buffer_get_image_data, arv_buffer_get_image_pixel_format,
  arv_buffer_get_image_width, arv_buffer_get_image_height,
  arv_buffer_get_image_x, arv_buffer_get_image_y.
- Chunk helpers (optional V1): arv_buffer_has_chunks, arv_buffer_get_chunk_data.

### GenICam node access (BGAPI2-style)
- Core: arv_gc_get_node, arv_gc_get_device, arv_gc_set_buffer, arv_gc_get_buffer.
- Node access base: arv_gc_node_get_genicam.
- Feature node helpers: arv_gc_feature_node_get_name, arv_gc_feature_node_get_description,
  arv_gc_feature_node_get_display_name, arv_gc_feature_node_is_available,
  arv_gc_feature_node_is_implemented, arv_gc_feature_node_get_value_as_string,
  arv_gc_feature_node_set_value_from_string.
- Typed nodes: arv_gc_integer_* , arv_gc_float_* , arv_gc_boolean_* ,
  arv_gc_string_* , arv_gc_command_execute, arv_gc_enumeration_* ,
  arv_gc_enumeration_get_entries, arv_gc_enum_entry_get_value.

### Enums and types
- ArvBufferStatus, ArvBufferPayloadType, ArvPixelFormat, ArvAcquisitionMode,
  ArvAuto, ArvExposureMode, ArvGcRepresentation, ArvGcAccessMode,
  ArvRegisterCachePolicy, ArvRangeCheckPolicy, ArvAccessCheckPolicy,
  ArvDeviceError.

### GLib/GObject helpers
- g_object_ref, g_object_unref, g_object_get, g_object_set.
- g_error_free, g_clear_error (if used), g_free, g_strfreev (for dup string arrays).

## Phase 2: Core wrapper types
- Define Julia wrapper structs that hold `Ptr{T}` plus ownership flag.
- Add finalizers for GObject ref/unref and explicit `close`/`destroy` methods.
- Implement reusable per-object string buffers for getters (no allocs per call).

## Phase 3: Buffer pool + zero-alloc acquisition
- Implement `Buffer` wrapper analogous to BGAPI2.Buffer:
  - Allow user-provided `Vector{UInt8}`.
  - Store the Julia buffer to keep it alive.
  - Use `GC.@preserve` around pointer use.
- Implement `BufferPool`:
  - Create N buffers of a fixed size.
  - Queue all buffers to stream.
  - Hot loop uses `stream_timeout_pop_buffer` and `stream_push_buffer` with no allocations.
- Provide an example polled acquisition loop using only pointers and reuse.

## Phase 4: Device/camera configuration
- Wrap common property accessors and GenICam node access via ArvDevice/ArvGc, following BGAPI2.jl node access patterns.
- Provide a minimal feature API for setting exposure, gain, frame rate, etc.

## Phase 5: Ergonomics + docs
- Add a minimal user guide that mirrors BGAPI2.jl usage patterns.
- Document thread-safety constraints and polling-only semantics.

## Phase 6: Testing
- Add unit tests for:
  - wrapper construction + lifetime handling.
  - buffer pool creation and reuse.
  - polling loop with timeouts (mocked or minimal checks).
- Integration tests use arv-fake-gv-camera.

## Module and file layout (BGAPI2.jl style)
- `src/Aravis.jl`: main module, exports, include order.
- `src/LibAravis.jl`: low-level ccall wrappers.
- `src/system.jl`: system-level device/interface enumeration helpers.
- `src/interface.jl`: interface-specific device discovery and open.
- `src/camera.jl`: ArvCamera wrapper and convenience accessors.
- `src/device.jl`: ArvDevice wrapper and GenICam feature access.
- `src/stream.jl`: ArvStream wrapper and polling helpers.
- `src/buffer.jl`: ArvBuffer wrapper + external buffer ownership.
- `src/gc.jl`: ArvGc + ArvGcNode + typed node accessors.
- `src/exceptions.jl`: map GError/ArvDeviceError to Julia exceptions.
- `test/`: arv-fake-gv-camera integration tests + unit tests.

## Naming conventions
- Map C names to idiomatic Julia snake_case (as in BGAPI2.jl).
- Group functionality via modules/files rather than C prefix namespaces.
- Keep raw bindings close to C names; expose Julia-friendly wrappers in public API.

## Future extensions (non-blocking)
- Signals and async callbacks (if needed) with GLib main loop wrapper.
- Higher-level GenICam node mapping.
- JLL update to Aravis 0.9.1 for GenTL features.
