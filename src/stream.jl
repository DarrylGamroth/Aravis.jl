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

function Base.show(io::IO, ::MIME"text/plain", stream::Stream)
    if stream.handle == C_NULL
        print(io, "Stream: <closed>")
        return
    end
    completed = 0
    failures = 0
    underruns = 0
    try
        completed, failures, underruns = get_statistics(stream)
    catch
    end
    println(io, "Stream")
    println(io, "  Completed: ", completed)
    println(io, "  Failures: ", failures)
    println(io, "  Underruns: ", underruns)
end

function Base.close(stream::Stream)
    if stream.handle != C_NULL
        GLib.g_object_unref(Ptr{Cvoid}(stream.handle))
        stream.handle = C_NULL
    end
    return nothing
end

mutable struct BufferPool
    stream::Stream
    buffers::Vector{Buffer}
    buffer_size::Int
end

function Base.show(io::IO, ::MIME"text/plain", pool::BufferPool)
    println(io, "BufferPool")
    println(io, "  Buffers: ", length(pool.buffers))
    println(io, "  Buffer Size: ", pool.buffer_size)
end

function _buffer_from_ptr(pool::BufferPool, ptr::Ptr{LibAravis.ArvBuffer})
    for buf in pool.buffers
        if buf.handle == ptr
            return buf
        end
    end
    return nothing
end

function push_buffer!(stream::Stream, buffer::Buffer)
    LibAravis.arv_stream_push_buffer(stream.handle, buffer.handle)
    return nothing
end


function start_thread!(stream::Stream)
    LibAravis.arv_stream_start_thread(stream.handle)
    return nothing
end

function stop_thread!(stream::Stream; delete_buffers::Bool=false)
    LibAravis.arv_stream_stop_thread(stream.handle, delete_buffers ? 1 : 0)
    return nothing
end

function get_statistics(stream::Stream)
    completed = Ref{UInt64}()
    failures = Ref{UInt64}()
    underruns = Ref{UInt64}()
    LibAravis.arv_stream_get_statistics(stream.handle, completed, failures, underruns)
    return (completed[], failures[], underruns[])
end

function delete_buffers!(stream::Stream)
    LibAravis.arv_stream_stop_thread(stream.handle, 1)
    return nothing
end

function BufferPool(stream::Stream, n_buffers::Integer, buffer_size::Integer)
    buffers = Vector{Buffer}(undef, n_buffers)
    for i in 1:n_buffers
        ptr = LibAravis.arv_buffer_new_allocate(buffer_size)
        buffers[i] = Buffer(ptr; owns=false)
        push_buffer!(stream, buffers[i])
    end
    return BufferPool(stream, buffers, buffer_size)
end

function BufferPool(stream::Stream, buffers::Vector{<:StridedVector{UInt8}})
    n_buffers = length(buffers)
    pool_buffers = Vector{Buffer}(undef, n_buffers)
    buffer_size = 0
    for i in 1:n_buffers
        stride(buffers[i], 1) == 1 || throw(ArgumentError("All buffers must be contiguous"))
        pool_buffers[i] = Buffer(buffers[i])
        push_buffer!(stream, pool_buffers[i])
        if i == 1
            buffer_size = sizeof(eltype(buffers[i])) * length(buffers[i])
        else
            this_size = sizeof(eltype(buffers[i])) * length(buffers[i])
            this_size == buffer_size || throw(ArgumentError("All buffers must have the same size"))
        end
    end
    return BufferPool(stream, pool_buffers, buffer_size)
end

function pop_buffer!(pool::BufferPool)
    ptr = LibAravis.arv_stream_pop_buffer(pool.stream.handle)
    ptr == C_NULL && return nothing
    buf = _buffer_from_ptr(pool, ptr)
    return buf === nothing ? Buffer(ptr; owns=false) : buf
end

function try_pop_buffer!(pool::BufferPool)
    ptr = LibAravis.arv_stream_try_pop_buffer(pool.stream.handle)
    ptr == C_NULL && return nothing
    buf = _buffer_from_ptr(pool, ptr)
    return buf === nothing ? Buffer(ptr; owns=false) : buf
end

function timeout_pop_buffer!(pool::BufferPool, timeout_ns::UInt64)
    ptr = LibAravis.arv_stream_timeout_pop_buffer(pool.stream.handle, timeout_ns)
    ptr == C_NULL && return nothing
    buf = _buffer_from_ptr(pool, ptr)
    return buf === nothing ? Buffer(ptr; owns=false) : buf
end

function queue_buffer!(pool::BufferPool, buffer::Buffer)
    push_buffer!(pool.stream, buffer)
    return nothing
end
