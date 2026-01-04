@testset "Aravis fake camera acquisition" begin
    @test device_count() > 0
    cam = open_camera()
    stream = Stream(cam)
    pool = BufferPool(stream, 4, payload(cam))

    try
        start_acquisition!(cam)
        buf = timeout_pop_buffer!(pool, UInt64(1_000_000_000))
        @test buf !== nothing
        if buf !== nothing
            @test status(buf) != LibAravis.ARV_BUFFER_STATUS_TIMEOUT
            queue_buffer!(pool, buf)
        end
    finally
        try
            stop_acquisition!(cam)
        catch
        end
        Aravis.close(stream)
        Aravis.close(cam)
    end
end
