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
