@testset "Aravis allocation-free acquisition" begin
    with_fake_camera() do
        cam = open_camera()
        stream = create_stream(cam)
        pool = BufferPool(stream, 4, payload(cam))

        try
            start_acquisition!(cam)
            for _ in 1:2
                buf = timeout_pop_buffer!(pool, UInt64(1_000_000_000))
                buf === nothing && continue
                queue_buffer!(pool, buf)
            end

            alloc = @allocated begin
                for _ in 1:5
                    buf = timeout_pop_buffer!(pool, UInt64(1_000_000_000))
                    buf === nothing && continue
                    b = buf::Buffer
                    queue_buffer!(pool, b)
                end
            end
            @test alloc == 0
        finally
            try
                stop_acquisition!(cam)
            catch
            end
            Aravis.close(stream)
            Aravis.close(cam)
        end
    end
end
