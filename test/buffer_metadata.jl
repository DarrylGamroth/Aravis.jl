@testset "Aravis buffer metadata" begin
    cam = open_camera()
    stream = Stream(cam)
    pool = BufferPool(stream, 4, payload(cam))

    try
        start_acquisition!(cam)
        buf = timeout_pop_buffer!(pool, UInt64(1_000_000_000))
        @test buf !== nothing
        if buf !== nothing
            @test status(buf) != LibAravis.ARV_BUFFER_STATUS_TIMEOUT
            @test payload_type(buf) != 0
            @test frame_id(buf) >= 0
            @test timestamp(buf) >= 0

            size_ref = Ref{Csize_t}(0)
            _ = image_data_ptr!(buf, size_ref)
            @test size_ref[] > 0
            @test size_ref[] <= payload(cam)

            size_ref[] = 0
            _ = data_ptr!(buf, size_ref)
            @test size_ref[] > 0
            @test size_ref[] <= payload(cam)

            queue_buffer!(pool, buf)
        end
    finally
        try
            stop_acquisition!(cam)
        catch
        end
        close(stream)
        close(cam)
    end
end
