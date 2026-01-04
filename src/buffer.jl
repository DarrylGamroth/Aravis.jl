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

function status(buffer::Buffer)
    LibAravis.arv_buffer_get_status(buffer.handle)
end

function payload_type(buffer::Buffer)
    LibAravis.arv_buffer_get_payload_type(buffer.handle)
end

function timestamp(buffer::Buffer)
    LibAravis.arv_buffer_get_timestamp(buffer.handle)
end

function frame_id(buffer::Buffer)
    LibAravis.arv_buffer_get_frame_id(buffer.handle)
end

function data_ptr!(buffer::Buffer, size_ref::Base.RefValue{Csize_t})
    ptr = LibAravis.arv_buffer_get_data(buffer.handle, size_ref)
    return Ptr{Cvoid}(ptr)
end

function image_data_ptr!(buffer::Buffer, size_ref::Base.RefValue{Csize_t})
    ptr = LibAravis.arv_buffer_get_image_data(buffer.handle, size_ref)
    return Ptr{Cvoid}(ptr)
end
