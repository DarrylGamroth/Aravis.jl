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
