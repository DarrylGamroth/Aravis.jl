mutable struct Buffer <: ArvObject
    handle::Ptr{LibAravis.ArvBuffer}
    owns::Bool
    string_buffer::Vector{UInt8}
    external_buffer::Union{Nothing, AbstractVector}
end

function Buffer(handle::Ptr{LibAravis.ArvBuffer}; owns::Bool=false)
    _check_ptr(handle, "ArvBuffer")
    obj = Buffer(handle, owns, Vector{UInt8}(undef, 64), nothing)
    _register_finalizer!(obj)
    return obj
end

function Buffer(size::Integer)
    ptr = LibAravis.arv_buffer_new_allocate(size)
    return Buffer(ptr; owns=true)
end

function Buffer(user_buffer::StridedVector{T}) where {T}
    isbitstype(T) || throw(ArgumentError("External buffer element type must be isbits"))
    stride(user_buffer, 1) == 1 || throw(ArgumentError("External buffer must be contiguous (stride == 1)"))
    sz = sizeof(T) * length(user_buffer)
    ptr = Ref{Ptr{LibAravis.ArvBuffer}}(C_NULL)
    GC.@preserve user_buffer begin
        ptr[] = LibAravis.arv_buffer_new(sz, pointer(user_buffer))
    end
    buf = Buffer(ptr[]; owns=true)
    buf.external_buffer = user_buffer
    return buf
end
