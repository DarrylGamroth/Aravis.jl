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

mutable struct BufferPool
    stream::Stream
    buffers::Vector{Buffer}
    buffer_size::Int
end

function _buffer_from_ptr(pool::BufferPool, ptr::Ptr{LibAravis.ArvBuffer})
    for buf in pool.buffers
        if buf.handle == ptr
            return buf
        end
    end
    return nothing
end

function push_buffer(stream::Stream, buffer::Buffer)
    LibAravis.arv_stream_push_buffer(stream.handle, buffer.handle)
    return nothing
end

function pop_buffer(stream::Stream)
    ptr = LibAravis.arv_stream_pop_buffer(stream.handle)
    return ptr == C_NULL ? nothing : ptr
end

function try_pop_buffer(stream::Stream)
    ptr = LibAravis.arv_stream_try_pop_buffer(stream.handle)
    return ptr == C_NULL ? nothing : ptr
end

function timeout_pop_buffer(stream::Stream, timeout_ns::UInt64)
    ptr = LibAravis.arv_stream_timeout_pop_buffer(stream.handle, timeout_ns)
    return ptr == C_NULL ? nothing : ptr
end

function start_acquisition(stream::Stream)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ok = LibAravis.arv_stream_start_acquisition(stream.handle, err)
    _throw_if_gerror!(err)
    ok == 0 && throw(ErrorException("Failed to start acquisition"))
    return nothing
end

function stop_acquisition(stream::Stream)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ok = LibAravis.arv_stream_stop_acquisition(stream.handle, err)
    _throw_if_gerror!(err)
    ok == 0 && throw(ErrorException("Failed to stop acquisition"))
    return nothing
end

function get_statistics(stream::Stream)
    completed = Ref{UInt64}()
    failures = Ref{UInt64}()
    underruns = Ref{UInt64}()
    LibAravis.arv_stream_get_statistics(stream.handle, completed, failures, underruns)
    return (completed[], failures[], underruns[])
end

function BufferPool(stream::Stream, n_buffers::Integer, buffer_size::Integer)
    buffers = Vector{Buffer}(undef, n_buffers)
    for i in 1:n_buffers
        buffers[i] = Buffer(buffer_size)
        push_buffer(stream, buffers[i])
    end
    return BufferPool(stream, buffers, buffer_size)
end

function BufferPool(stream::Stream, buffers::Vector{<:AbstractVector})
    n_buffers = length(buffers)
    pool_buffers = Vector{Buffer}(undef, n_buffers)
    buffer_size = 0
    for i in 1:n_buffers
        pool_buffers[i] = Buffer(buffers[i])
        push_buffer(stream, pool_buffers[i])
        if i == 1
            buffer_size = sizeof(eltype(buffers[i])) * length(buffers[i])
        end
    end
    return BufferPool(stream, pool_buffers, buffer_size)
end

function pop_buffer(pool::BufferPool)
    ptr = LibAravis.arv_stream_pop_buffer(pool.stream.handle)
    ptr == C_NULL && return nothing
    buf = _buffer_from_ptr(pool, ptr)
    return buf === nothing ? Buffer(ptr; owns=false) : buf
end

function try_pop_buffer(pool::BufferPool)
    ptr = LibAravis.arv_stream_try_pop_buffer(pool.stream.handle)
    ptr == C_NULL && return nothing
    buf = _buffer_from_ptr(pool, ptr)
    return buf === nothing ? Buffer(ptr; owns=false) : buf
end

function timeout_pop_buffer(pool::BufferPool, timeout_ns::UInt64)
    ptr = LibAravis.arv_stream_timeout_pop_buffer(pool.stream.handle, timeout_ns)
    ptr == C_NULL && return nothing
    buf = _buffer_from_ptr(pool, ptr)
    return buf === nothing ? Buffer(ptr; owns=false) : buf
end

function queue_buffer(pool::BufferPool, buffer::Buffer)
    push_buffer(pool.stream, buffer)
    return nothing
end
