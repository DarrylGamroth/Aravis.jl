@testset "Aravis camera configuration" begin
    cam = open_camera()
    try
        x, y, w, h = region(cam)
        set_region(cam, x, y, w, h)
        @test region(cam) == (x, y, w, h)

        fmt = pixel_format_string(cam)
        pixel_format!(cam, fmt)
        @test pixel_format_string(cam) == fmt

        fr = frame_rate(cam)
        frame_rate!(cam, fr)
        @test frame_rate(cam) == fr

        exp = exposure_time(cam)
        exposure_time!(cam, exp)
        @test exposure_time(cam) == exp

        g = gain(cam)
        gain!(cam, g)
        @test gain(cam) == g
    finally
        close(cam)
    end
end
