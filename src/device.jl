mutable struct Device <: ArvObject
    handle::Ptr{LibAravis.ArvDevice}
    owns::Bool
    string_buffer::Vector{UInt8}
end

function Device(handle::Ptr{LibAravis.ArvDevice}; owns::Bool=false)
    _check_ptr(handle, "ArvDevice")
    obj = Device(handle, owns, Vector{UInt8}(undef, 64))
    _register_finalizer!(obj)
    return obj
end

function Stream(device::Device)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_device_create_stream_full(device.handle, C_NULL, C_NULL, C_NULL, err)
    _throw_if_gerror!(err)
    return Stream(ptr; owns=false)
end

function is_feature_available(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ok = LibAravis.arv_device_is_feature_available(device.handle, feature, err)
    _throw_if_gerror!(err)
    return ok != 0
end

function is_feature_implemented(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ok = LibAravis.arv_device_is_feature_implemented(device.handle, feature, err)
    _throw_if_gerror!(err)
    return ok != 0
end

function boolean_feature_value(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_device_get_boolean_feature_value(device.handle, feature, err)
    _throw_if_gerror!(err)
    return value != 0
end

function boolean_feature_value!(device::Device, feature::AbstractString, value::Bool)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_device_set_boolean_feature_value(device.handle, feature, value ? 1 : 0, err)
    _throw_if_gerror!(err)
    return nothing
end

function integer_feature_value(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_device_get_integer_feature_value(device.handle, feature, err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function integer_feature_value!(device::Device, feature::AbstractString, value::Integer)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_device_set_integer_feature_value(device.handle, feature, Int64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function integer_feature_bounds(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    min = Ref{LibAravis.gint64}()
    max = Ref{LibAravis.gint64}()
    LibAravis.arv_device_get_integer_feature_bounds(device.handle, feature, min, max, err)
    _throw_if_gerror!(err)
    return (Int64(min[]), Int64(max[]))
end

function integer_feature_increment(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_device_get_integer_feature_increment(device.handle, feature, err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function float_feature_value(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_device_get_float_feature_value(device.handle, feature, err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function float_feature_value!(device::Device, feature::AbstractString, value::Real)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_device_set_float_feature_value(device.handle, feature, Float64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function float_feature_bounds(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    min = Ref{Cdouble}()
    max = Ref{Cdouble}()
    LibAravis.arv_device_get_float_feature_bounds(device.handle, feature, min, max, err)
    _throw_if_gerror!(err)
    return (Float64(min[]), Float64(max[]))
end

function float_feature_increment(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_device_get_float_feature_increment(device.handle, feature, err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function string_feature_value(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_device_get_string_feature_value(device.handle, feature, err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function string_feature_value!(device::Device, feature::AbstractString, value::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_device_set_string_feature_value(device.handle, feature, value, err)
    _throw_if_gerror!(err)
    return nothing
end

function execute_command(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_device_execute_command(device.handle, feature, err)
    _throw_if_gerror!(err)
    return nothing
end

function register_feature_value!(device::Device, feature::AbstractString, data::AbstractVector{UInt8})
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    GC.@preserve data begin
        LibAravis.arv_device_set_register_feature_value(device.handle, feature, UInt64(length(data)), pointer(data), err)
    end
    _throw_if_gerror!(err)
    return nothing
end

function register_feature_value(device::Device, feature::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    length_ref = Ref{LibAravis.guint64}()
    ptr = LibAravis.arv_device_dup_register_feature_value(device.handle, feature, length_ref, err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return UInt8[]
    len = Int(length_ref[])
    data = Vector{UInt8}(undef, len)
    unsafe_copyto!(pointer(data), Ptr{UInt8}(ptr), len)
    GLib.g_free(ptr)
    return data
end


function feature(device::Device, ::Type{Bool}, name::AbstractString)
    return boolean_feature_value(device, name)
end

function feature(device::Device, ::Type{T}, name::AbstractString) where {T<:Integer}
    return convert(T, integer_feature_value(device, name))
end

function feature(device::Device, ::Type{T}, name::AbstractString) where {T<:AbstractFloat}
    return convert(T, float_feature_value(device, name))
end

function feature(device::Device, ::Type{String}, name::AbstractString)
    return string_feature_value(device, name)
end

function feature!(device::Device, name::AbstractString, value::Bool)
    return boolean_feature_value!(device, name, value)
end

function feature!(device::Device, name::AbstractString, value::Integer)
    return integer_feature_value!(device, name, value)
end

function feature!(device::Device, name::AbstractString, value::AbstractFloat)
    return float_feature_value!(device, name, value)
end

function feature!(device::Device, name::AbstractString, value::AbstractString)
    return string_feature_value!(device, name, value)
end

Base.getindex(device::Device, name::AbstractString) = node(device, name)
Base.getindex(device::Device, name::Symbol) = node(device, string(name))
