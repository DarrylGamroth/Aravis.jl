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

mutable struct GcNode <: ArvObject
    handle::Ptr{LibAravis.ArvGcNode}
    owns::Bool
    string_buffer::Vector{UInt8}
end

function GcNode(handle::Ptr{LibAravis.ArvGcNode}; owns::Bool=false)
    _check_ptr(handle, "ArvGcNode")
    obj = GcNode(handle, owns, Vector{UInt8}(undef, 64))
    _register_finalizer!(obj)
    return obj
end

function genicam(device::Device)
    ptr = LibAravis.arv_device_get_genicam(device.handle)
    return Gc(ptr; owns=false)
end

function node(genicam::Gc, name::AbstractString)
    ptr = LibAravis.arv_gc_get_node(genicam.handle, name)
    return GcNode(ptr; owns=false)
end

function node(device::Device, name::AbstractString)
    ptr = LibAravis.arv_device_get_feature(device.handle, name)
    return GcNode(ptr; owns=false)
end

function buffer(genicam::Gc)
    ptr = LibAravis.arv_gc_get_buffer(genicam.handle)
    ptr == C_NULL && return nothing
    return Buffer(ptr; owns=false)
end

function buffer!(genicam::Gc, buffer::Buffer)
    LibAravis.arv_gc_set_buffer(genicam.handle, buffer.handle)
    return nothing
end

gc_buffer(genicam::Gc) = buffer(genicam)
gc_buffer!(genicam::Gc, buf::Buffer) = buffer!(genicam, buf)

function name(node::GcNode)
    ptr = LibAravis.arv_gc_feature_node_get_name(Ptr{LibAravis.ArvGcFeatureNode}(node.handle))
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function description(node::GcNode)
    ptr = LibAravis.arv_gc_feature_node_get_description(Ptr{LibAravis.ArvGcFeatureNode}(node.handle))
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function display_name(node::GcNode)
    ptr = LibAravis.arv_gc_feature_node_get_display_name(Ptr{LibAravis.ArvGcFeatureNode}(node.handle))
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function tool_tip(node::GcNode)
    ptr = LibAravis.arv_gc_feature_node_get_tooltip(Ptr{LibAravis.ArvGcFeatureNode}(node.handle))
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function is_available(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ok = LibAravis.arv_gc_feature_node_is_available(Ptr{LibAravis.ArvGcFeatureNode}(node.handle), err)
    _throw_if_gerror!(err)
    return ok != 0
end

function is_implemented(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ok = LibAravis.arv_gc_feature_node_is_implemented(Ptr{LibAravis.ArvGcFeatureNode}(node.handle), err)
    _throw_if_gerror!(err)
    return ok != 0
end

function is_locked(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ok = LibAravis.arv_gc_feature_node_is_locked(Ptr{LibAravis.ArvGcFeatureNode}(node.handle), err)
    _throw_if_gerror!(err)
    return ok != 0
end

function imposed_access_mode(node::GcNode)
    LibAravis.arv_gc_feature_node_get_imposed_access_mode(Ptr{LibAravis.ArvGcFeatureNode}(node.handle))
end

function actual_access_mode(node::GcNode)
    LibAravis.arv_gc_feature_node_get_actual_access_mode(Ptr{LibAravis.ArvGcFeatureNode}(node.handle))
end

function value(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_gc_feature_node_get_value_as_string(Ptr{LibAravis.ArvGcFeatureNode}(node.handle), err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function value!(node::GcNode, v::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_feature_node_set_value_from_string(Ptr{LibAravis.ArvGcFeatureNode}(node.handle), v, err)
    _throw_if_gerror!(err)
    return nothing
end

function value(node::GcNode, ::Type{String})
    return value(node)
end

function value(node::GcNode, ::Type{Bool})
    return bool_value(node)
end

function value(node::GcNode, ::Type{T}) where {T<:Integer}
    return convert(T, integer_value(node))
end

function value(node::GcNode, ::Type{T}) where {T<:AbstractFloat}
    return convert(T, float_value(node))
end

function value!(node::GcNode, v::Bool)
    return bool_value!(node, v)
end

function value!(node::GcNode, v::Integer)
    return integer_value!(node, v)
end

function value!(node::GcNode, v::AbstractFloat)
    return float_value!(node, v)
end

function integer_value(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_value(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function integer_value!(node::GcNode, value::Integer)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_integer_set_value(Ptr{LibAravis.ArvGcInteger}(node.handle), Int64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function integer_min(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_min(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function integer_max(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_max(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function integer_inc(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_inc(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function float_value(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_value(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function float_value!(node::GcNode, value::Real)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_float_set_value(Ptr{LibAravis.ArvGcFloat}(node.handle), Float64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function float_min(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_min(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function float_max(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_max(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function float_inc(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_inc(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function bool_value(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_boolean_get_value(Ptr{LibAravis.ArvGcBoolean}(node.handle), err)
    _throw_if_gerror!(err)
    return value != 0
end

function bool_value!(node::GcNode, value::Bool)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_boolean_set_value(Ptr{LibAravis.ArvGcBoolean}(node.handle), value ? 1 : 0, err)
    _throw_if_gerror!(err)
    return nothing
end

function string_value(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_gc_string_get_value(Ptr{LibAravis.ArvGcString}(node.handle), err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function string_value!(node::GcNode, value::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_string_set_value(Ptr{LibAravis.ArvGcString}(node.handle), value, err)
    _throw_if_gerror!(err)
    return nothing
end

Base.getindex(genicam::Gc, name::AbstractString) = node(genicam, name)
Base.getindex(genicam::Gc, name::Symbol) = node(genicam, string(name))

Base.getindex(node::GcNode) = value(node)
Base.getindex(node::GcNode, ::Type{T}) where {T} = value(node, T)
Base.setindex!(node::GcNode, v) = (value!(node, v); node)

Base.convert(::Type{Bool}, node::GcNode) = bool_value(node)
Base.convert(::Type{T}, node::GcNode) where {T<:Integer} = convert(T, integer_value(node))
Base.convert(::Type{T}, node::GcNode) where {T<:AbstractFloat} = convert(T, float_value(node))
Base.convert(::Type{String}, node::GcNode) = value(node)
