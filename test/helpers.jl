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
