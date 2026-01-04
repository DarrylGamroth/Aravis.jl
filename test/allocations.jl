@noinline function _acquire_cycle!(pool::BufferPool, timeout_ns::UInt64)
    buf = timeout_pop_buffer!(pool, timeout_ns)
    buf === nothing && return nothing
    queue_buffer!(pool, buf)
    return nothing
end

@noinline function _measure_acquire_allocs(pool::BufferPool, timeout_ns::UInt64, cycles::Int)
    return @allocated begin
        @inbounds for _ in 1:cycles
            _acquire_cycle!(pool, timeout_ns)
        end
    end
end

@testset "Aravis allocation-free acquisition" begin
    cam = open_camera()
    stream = Stream(cam)
    pool = BufferPool(stream, 4, payload(cam))
    timeout_ns = UInt64(1_000_000_000)

    try
        start_acquisition!(cam)
        for _ in 1:2
            _acquire_cycle!(pool, timeout_ns)
        end

        alloc = _measure_acquire_allocs(pool, timeout_ns, 5)
        @test alloc == 0
    finally
        try
            stop_acquisition!(cam)
        catch
        end
        close(stream)
        close(cam)
    end
end
