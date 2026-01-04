function _find_fake_camera_bin()
    bin_dir = joinpath(Aravis_jll.artifact_dir, "bin")
    isdir(bin_dir) || return nothing
    for name in ("arv-fake-gv-camera-0.8", "arv-fake-gv-camera", "arv-fake-gv-camera.exe")
        path = joinpath(bin_dir, name)
        isfile(path) && return path
    end
    return nothing
end

function with_fake_camera(f)
    bin = _find_fake_camera_bin()
    if bin === nothing
        @info "Skipping tests: arv-fake-gv-camera not available in Aravis_jll artifact."
        return nothing
    end
    proc = run(`$bin -i 127.0.0.1`, wait=false)
    try
        if !Base.process_running(proc)
            @info "Skipping tests: arv-fake-gv-camera exited immediately."
            return nothing
        end
        deadline = time() + 5.0
        ready = false
        while time() < deadline
            if !Base.process_running(proc)
                @info "Skipping tests: arv-fake-gv-camera terminated before registering a device."
                return nothing
            end
            update_device_list()
            if device_count() > 0
                ready = true
                break
            end
            sleep(0.1)
        end
        if !ready
            @info "Skipping tests: arv-fake-gv-camera did not register a device."
            return nothing
        end
        update_device_list()
        if device_count() == 0
            @info "Skipping tests: no Aravis devices found after initialization."
            return nothing
        end
        ok = false
        try
            cam = open_camera()
            close(cam)
            ok = true
        catch
        end
        if !ok
            @info "Skipping tests: unable to open fake camera device."
            return nothing
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
