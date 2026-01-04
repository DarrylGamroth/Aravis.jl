mutable struct Stream <: ArvObject
    handle::Ptr{LibAravis.ArvStream}
    owns::Bool
    string_buffer::Vector{UInt8}
end

function Stream(handle::Ptr{LibAravis.ArvStream}; owns::Bool=false)
    _check_ptr(handle, "ArvStream")
    obj = Stream(handle, owns, Vector{UInt8}(undef, 64))
    _register_finalizer!(obj)
    return obj
end
