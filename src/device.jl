mutable struct Device <: ArvObject
    handle::Ptr{LibAravis.ArvDevice}
    owns::Bool
    string_buffer::Vector{UInt8}
end

function Device(handle::Ptr{LibAravis.ArvDevice}; owns::Bool=false)
    _check_ptr(handle, "ArvDevice")
    obj = Device(handle, owns, Vector{UInt8}(undef, 64))
    _register_finalizer!(obj)
    return obj
end

function create_stream(device::Device)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_device_create_stream_full(device.handle, C_NULL, C_NULL, C_NULL, err)
    _throw_if_gerror!(err)
    return Stream(ptr; owns=false)
end
