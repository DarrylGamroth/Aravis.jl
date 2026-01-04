mutable struct Interface <: ArvObject
    handle::Ptr{LibAravis.ArvInterface}
    owns::Bool
    string_buffer::Vector{UInt8}
end

function Interface(handle::Ptr{LibAravis.ArvInterface}; owns::Bool=false)
    _check_ptr(handle, "ArvInterface")
    obj = Interface(handle, owns, Vector{UInt8}(undef, 64))
    _register_finalizer!(obj)
    return obj
end
