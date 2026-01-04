function update_device_list()
    LibAravis.arv_update_device_list()
    return nothing
end

function device_count()
    return Int(LibAravis.arv_get_n_devices())
end

function device_id(index::Integer)
    ptr = LibAravis.arv_get_device_id(UInt32(index))
    ptr == C_NULL && return nothing
    return unsafe_string(ptr)
end

function open_device(device_id::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_open_device(device_id, err)
    _throw_if_gerror!(err)
    return Device(ptr; owns=true)
end

function open_device(index::Integer)
    id = device_id(index)
    id === nothing && throw(ArgumentError("Device index out of range"))
    return open_device(id)
end
