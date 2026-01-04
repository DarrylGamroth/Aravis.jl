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

function device_count(interface::Interface)
    return Int(LibAravis.arv_interface_get_n_devices(interface.handle))
end

function _iface_string(ptr::Cstring)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function device_id(interface::Interface, index::Integer)
    ptr = LibAravis.arv_interface_get_device_id(interface.handle, UInt32(index))
    return _iface_string(ptr)
end

function device_vendor(interface::Interface, index::Integer)
    ptr = LibAravis.arv_interface_get_device_vendor(interface.handle, UInt32(index))
    return _iface_string(ptr)
end

function device_model(interface::Interface, index::Integer)
    ptr = LibAravis.arv_interface_get_device_model(interface.handle, UInt32(index))
    return _iface_string(ptr)
end

function device_serial_number(interface::Interface, index::Integer)
    ptr = LibAravis.arv_interface_get_device_serial_nbr(interface.handle, UInt32(index))
    return _iface_string(ptr)
end

function device_protocol(interface::Interface, index::Integer)
    ptr = LibAravis.arv_interface_get_device_protocol(interface.handle, UInt32(index))
    return _iface_string(ptr)
end

function Base.show(io::IO, ::MIME"text/plain", interface::Interface)
    count = 0
    try
        count = device_count(interface)
    catch
    end
    println(io, "Interface")
    println(io, "  Devices: ", count)
    max_list = min(count, 3)
    for idx in 0:max_list-1
        id = device_id(interface, idx)
        vendor = device_vendor(interface, idx)
        model = device_model(interface, idx)
        serial = device_serial_number(interface, idx)
        proto = device_protocol(interface, idx)
        println(io, "  [", idx + 1, "] ", id)
        println(io, "    Vendor: ", vendor)
        println(io, "    Model: ", model)
        println(io, "    Serial: ", serial)
        println(io, "    Protocol: ", proto)
    end
end
