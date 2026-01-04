using Test

using Aravis
using Aravis.LibAravis
using Aravis_jll

function with_fake_camera(f)
    bin = joinpath(Aravis_jll.artifact_dir, "bin", "arv-fake-gv-camera-0.8")
    proc = run(`$bin -i 127.0.0.1`, wait=false)
    try
        deadline = time() + 5.0
        while time() < deadline
            update_device_list()
            if device_count() > 0
                break
            end
            sleep(0.1)
        end
        return f()
    finally
        try
            kill(proc)
        catch
        end
        try
            wait(proc)
        catch
        end
    end
end

@testset "Aravis fake camera acquisition" begin
    with_fake_camera() do
        @test device_count() > 0
        cam = open_camera()
        stream = create_stream(cam)
        pool = BufferPool(stream, 4, payload(cam))

        try
            start_acquisition(cam)
            buf = timeout_pop_buffer(pool, UInt64(1_000_000_000))
            @test buf !== nothing
            if buf !== nothing
                @test status(buf) != LibAravis.ARV_BUFFER_STATUS_TIMEOUT
                queue_buffer(pool, buf)
            end
        finally
            try
                stop_acquisition(cam)
            catch
            end
            Aravis.close(stream)
            Aravis.close(cam)
        end
    end
end

@testset "Aravis feature access" begin
    with_fake_camera() do
        cam = open_camera()
        try
            dev = device(cam)
            @test is_feature_available(dev, "Width")
            width = get_integer_feature_value(dev, "Width")
            bounds = get_integer_feature_bounds(dev, "Width")
            @test width >= bounds[1]
            @test width <= bounds[2]

            gc = genicam(dev)
            width_node = node(gc, "Width")
            @test is_available(width_node)
            @test integer_value(width_node) == width
        finally
            Aravis.close(cam)
        end
    end
end
