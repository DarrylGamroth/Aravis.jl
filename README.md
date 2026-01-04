# Aravis.jl

[![CI](https://github.com/DarrylGamroth/Aravis.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/DarrylGamroth/Aravis.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DarrylGamroth/Aravis.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/DarrylGamroth/Aravis.jl)

Julia bindings for the Aravis GenICam/GigE Vision library.

## Install
```julia
using Pkg
Pkg.add(url="https://github.com/DarrylGamroth/Aravis.jl")
```

## Quick start
```julia
using Aravis

update_device_list()
cam = open_camera()
stream = Stream(cam)
pool = BufferPool(stream, 8, payload(cam))
start_acquisition!(cam)

timeout_ns = 1_000_000_000
buf = timeout_pop_buffer!(pool, timeout_ns)
buf !== nothing && queue_buffer!(pool, buf)

stop_acquisition!(cam)
close(stream)
close(cam)
```

## Docs
- `docs/usage.md`

## Tests
```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Benchmarks
```bash
julia --project=benchmark benchmark/benchmarks.jl
```
