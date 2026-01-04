# Aravis.jl Usage Guide (Plan B)

## Scope and constraints
- Linux-only.
- Polling-only API; signals and async callbacks are intentionally not supported.
- Favor deterministic, zero-allocation acquisition loops by reusing buffers.

## Basic discovery and open
```julia
using Aravis

update_device_list()
@assert device_count() > 0
cam = open_camera()
```

## Configure the camera
```julia
# Region
set_region(cam, 0, 0, 1024, 1024)
x, y, w, h = region(cam)

# Pixel format
pixel_format!(cam, "Mono8")
fmt = pixel_format_string(cam)

# Exposure and gain
exposure_time!(cam, 2000.0)
gain!(cam, 0.0)
```

## Buffer pool and polled acquisition
```julia
stream = create_stream(cam)
pool = BufferPool(stream, 8, payload(cam))

start_acquisition(cam)
buf = timeout_pop_buffer(pool, UInt64(1_000_000_000))
if buf !== nothing
    # Use image_data_ptr! or data_ptr! to access bytes without allocations.
    queue_buffer(pool, buf)
end
stop_acquisition(cam)

close(stream)
close(cam)
```

## GenICam node access (BGAPI2-style)
```julia
dev = device(cam)
gc = genicam(dev)
node_width = node(gc, "Width")
width = integer_value(node_width)
```

## Thread-safety and deterministic behavior
- The stream callback API is not exposed; keep acquisition in a single polling loop.
- Avoid allocations in the hot path by preallocating buffers and reusing them.
- If you need background threads, keep the Aravis calls on one thread and hand off
  raw pointers or buffer metadata to worker threads.
