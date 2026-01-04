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

function device_id(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_get_device_id(camera.handle, err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function serial_number(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_get_device_serial_number(camera.handle, err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function Base.show(io::IO, ::MIME"text/plain", camera::Camera)
    id = ""
    serial = ""
    vendor = ""
    model = ""
    try
        id = device_id(camera)
    catch
    end
    try
        serial = serial_number(camera)
    catch
    end
    try
        dev = device(camera)
        vendor = string_feature_value(dev, "DeviceVendorName")
        model = string_feature_value(dev, "DeviceModelName")
    catch
    end
    println(io, "Camera: ", id)
    println(io, "  Vendor: ", vendor)
    println(io, "  Model: ", model)
    println(io, "  Serial Number: ", serial)
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

function Stream(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_create_stream_full(camera.handle, C_NULL, C_NULL, C_NULL, err)
    _throw_if_gerror!(err)
    return Stream(ptr; owns=false)
end

function start_acquisition!(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_start_acquisition(camera.handle, err)
    _throw_if_gerror!(err)
    return nothing
end

function stop_acquisition!(camera::Camera)
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

function device(camera::Camera)
    ptr = LibAravis.arv_camera_get_device(camera.handle)
    return Device(ptr; owns=false)
end

function region!(camera::Camera, x::Integer, y::Integer, width::Integer, height::Integer)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_region(camera.handle, Int32(x), Int32(y), Int32(width), Int32(height), err)
    _throw_if_gerror!(err)
    return nothing
end

function region(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    x = Ref{LibAravis.gint}()
    y = Ref{LibAravis.gint}()
    width = Ref{LibAravis.gint}()
    height = Ref{LibAravis.gint}()
    LibAravis.arv_camera_get_region(camera.handle, x, y, width, height, err)
    _throw_if_gerror!(err)
    return (Int(x[]), Int(y[]), Int(width[]), Int(height[]))
end

function pixel_format(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    fmt = LibAravis.arv_camera_get_pixel_format(camera.handle, err)
    _throw_if_gerror!(err)
    return fmt
end

function pixel_format!(camera::Camera, fmt::LibAravis.ArvPixelFormat)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_pixel_format(camera.handle, fmt, err)
    _throw_if_gerror!(err)
    return nothing
end

function pixel_format!(camera::Camera, fmt::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_pixel_format_from_string(camera.handle, fmt, err)
    _throw_if_gerror!(err)
    return nothing
end

function pixel_format_string(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_camera_get_pixel_format_as_string(camera.handle, err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function frame_rate(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_camera_get_frame_rate(camera.handle, err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function frame_rate!(camera::Camera, value::Real)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_frame_rate(camera.handle, Float64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function frame_rate_bounds(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    min = Ref{Cdouble}()
    max = Ref{Cdouble}()
    LibAravis.arv_camera_get_frame_rate_bounds(camera.handle, min, max, err)
    _throw_if_gerror!(err)
    return (Float64(min[]), Float64(max[]))
end

function exposure_time(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_camera_get_exposure_time(camera.handle, err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function exposure_time!(camera::Camera, value::Real)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_exposure_time(camera.handle, Float64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function exposure_time_bounds(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    min = Ref{Cdouble}()
    max = Ref{Cdouble}()
    LibAravis.arv_camera_get_exposure_time_bounds(camera.handle, min, max, err)
    _throw_if_gerror!(err)
    return (Float64(min[]), Float64(max[]))
end

function exposure_time_auto(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_camera_get_exposure_time_auto(camera.handle, err)
    _throw_if_gerror!(err)
    return value
end

function exposure_time_auto!(camera::Camera, mode::LibAravis.ArvAuto)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_exposure_time_auto(camera.handle, mode, err)
    _throw_if_gerror!(err)
    return nothing
end

function gain(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_camera_get_gain(camera.handle, err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function gain!(camera::Camera, value::Real)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_gain(camera.handle, Float64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function gain_bounds(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    min = Ref{Cdouble}()
    max = Ref{Cdouble}()
    LibAravis.arv_camera_get_gain_bounds(camera.handle, min, max, err)
    _throw_if_gerror!(err)
    return (Float64(min[]), Float64(max[]))
end

function gain_auto(camera::Camera)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_camera_get_gain_auto(camera.handle, err)
    _throw_if_gerror!(err)
    return value
end

function gain_auto!(camera::Camera, mode::LibAravis.ArvAuto)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_camera_set_gain_auto(camera.handle, mode, err)
    _throw_if_gerror!(err)
    return nothing
end
