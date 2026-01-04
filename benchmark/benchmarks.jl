using BenchmarkTools
using Aravis
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

with_fake_camera() do
    cam = open_camera()
    stream = Stream(cam)
    pool = BufferPool(stream, 8, payload(cam))
    timeout_ns = UInt64(1_000_000_000)

    try
        start_acquisition!(cam)
        for _ in 1:3
            buf = timeout_pop_buffer!(pool, timeout_ns)
            buf === nothing && continue
            queue_buffer!(pool, buf)
        end

        println("Benchmark: timeout_pop_buffer! loop with BufferPool")
        trial = @benchmark begin
            buf = timeout_pop_buffer!(pool, $timeout_ns)
            if buf !== nothing
                queue_buffer!(pool, buf)
            end
        end samples=200 evals=1
        display(trial)
    finally
        try
            stop_acquisition!(cam)
        catch
        end
        close(stream)
        close(cam)
    end
end
