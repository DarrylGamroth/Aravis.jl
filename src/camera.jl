mutable struct Camera <: ArvObject
    handle::Ptr{LibAravis.ArvCamera}
    owns::Bool
    string_buffer::Vector{UInt8}
end

function Camera(handle::Ptr{LibAravis.ArvCamera}; owns::Bool=false)
    _check_ptr(handle, "ArvCamera")
    obj = Camera(handle, owns, Vector{UInt8}(undef, 64))
    _register_finalizer!(obj)
    return obj
end

function open_camera()
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_new(C_NULL, err)
    _throw_if_gerror!(err)
    return Camera(ptr; owns=true)
end

function open_camera(name::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_new(name, err)
    _throw_if_gerror!(err)
    return Camera(ptr; owns=true)
end

function open_camera(device::Device)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_new_with_device(device.handle, err)
    _throw_if_gerror!(err)
    return Camera(ptr; owns=true)
end

function open_camera(index::Integer)
    id = device_id(index)
    id === nothing && throw(ArgumentError("Camera index out of range"))
    return open_camera(id)
end

function create_stream(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_create_stream_full(camera.handle, C_NULL, C_NULL, C_NULL, err)
    _throw_if_gerror!(err)
    return Stream(ptr; owns=false)
end

function start_acquisition(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_start_acquisition(camera.handle, err)
    _throw_if_gerror!(err)
    return nothing
end

function stop_acquisition(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_stop_acquisition(camera.handle, err)
    _throw_if_gerror!(err)
    return nothing
end

function payload(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    size = LibAravis.arv_camera_get_payload(camera.handle, err)
    _throw_if_gerror!(err)
    return Int(size)
end
