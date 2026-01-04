mutable struct Gc <: ArvObject
    handle::Ptr{LibAravis.ArvGc}
    owns::Bool
    string_buffer::Vector{UInt8}
end

function Gc(handle::Ptr{LibAravis.ArvGc}; owns::Bool=false)
    _check_ptr(handle, "ArvGc")
    obj = Gc(handle, owns, Vector{UInt8}(undef, 64))
    _register_finalizer!(obj)
    return obj
end
