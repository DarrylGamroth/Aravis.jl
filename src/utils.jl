abstract type ArvObject end

function unsafe_handle(obj::ArvObject)
    obj.handle
end

function isopen(obj::ArvObject)
    obj.handle != C_NULL
end

function Base.close(obj::ArvObject)
    if obj.handle != C_NULL && obj.owns
        GLib.g_object_unref(Ptr{Cvoid}(obj.handle))
        obj.handle = C_NULL
    end
    return nothing
end

function _ensure_buffer!(buf::Vector{UInt8}, len::Integer)
    if length(buf) < len
        resize!(buf, len)
    end
    return buf
end

function _register_finalizer!(obj::ArvObject)
    if obj.owns
        finalizer(obj) do o
            if o.handle != C_NULL
                GLib.g_object_unref(Ptr{Cvoid}(o.handle))
                o.handle = C_NULL
            end
        end
    end
end

function _check_ptr(ptr, typename::AbstractString)
    ptr == C_NULL && throw(ArgumentError("$typename is NULL"))
    return ptr
end
