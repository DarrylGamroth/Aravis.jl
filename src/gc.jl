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

mutable struct GcNode{T} <: ArvObject
    handle::Ptr{LibAravis.ArvGcNode}
    owns::Bool
    string_buffer::Vector{UInt8}

    function GcNode(handle::Ptr{LibAravis.ArvGcNode}; owns::Bool=false)
        _check_ptr(handle, "ArvGcNode")
        T = _gcnode_detect_type(handle)
        obj = new{T}(handle, owns, Vector{UInt8}(undef, 64))
        _register_finalizer!(obj)
        return obj
    end

end

Base.eltype(::GcNode{T}) where {T} = T

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

function as_string(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_gc_feature_node_get_value_as_string(Ptr{LibAravis.ArvGcFeatureNode}(node.handle), err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function value(node::GcNode{Any})
    return as_string(node)
end

function value!(node::GcNode{Any}, v::AbstractString)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_feature_node_set_value_from_string(Ptr{LibAravis.ArvGcFeatureNode}(node.handle), v, err)
    _throw_if_gerror!(err)
    return nothing
end

function value(node::GcNode, ::Type{String})
    return value(node)
end

function value(node::GcNode, ::Type{Bool})
    return value(node::GcNode{Bool})
end

function value(node::GcNode, ::Type{T}) where {T<:Integer}
    return convert(T, value(node::GcNode{Int64}))
end

function value(node::GcNode, ::Type{T}) where {T<:AbstractFloat}
    return convert(T, value(node::GcNode{Float64}))
end

function value(node::GcNode{Bool})
    return _bool_value_unsafe(node)
end

function value(node::GcNode{T}) where {T<:Integer}
    return convert(T, _integer_value_unsafe(node))
end

function value(node::GcNode{T}) where {T<:AbstractFloat}
    return convert(T, _float_value_unsafe(node))
end

function value(node::GcNode{String})
    return _string_value_unsafe(node)
end

function value!(node::GcNode{Bool}, v::Bool)
    _bool_value_unsafe!(node, v)
    return nothing
end

function value!(node::GcNode{T}, v::T) where {T<:Integer}
    _integer_value_unsafe!(node, v)
    return nothing
end

function value!(node::GcNode{T}, v::T) where {T<:AbstractFloat}
    _float_value_unsafe!(node, v)
    return nothing
end

function value!(node::GcNode{String}, v::AbstractString)
    _string_value_unsafe!(node, v)
    return nothing
end

function _gcnode_detect_type(handle::Ptr{LibAravis.ArvGcNode})
    ptr = Ptr{LibAravis.GTypeInstance}(handle)
    LibAravis.g_type_check_instance_is_a(ptr, LibAravis.arv_gc_boolean_get_type()) != 0 && return Bool
    LibAravis.g_type_check_instance_is_a(ptr, LibAravis.arv_gc_integer_get_type()) != 0 && return Int64
    LibAravis.g_type_check_instance_is_a(ptr, LibAravis.arv_gc_float_get_type()) != 0 && return Float64
    LibAravis.g_type_check_instance_is_a(ptr, LibAravis.arv_gc_string_get_type()) != 0 && return String
    return Any
end

function _integer_value_unsafe(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_value(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function _integer_value_unsafe!(node::GcNode, value::Integer)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_integer_set_value(Ptr{LibAravis.ArvGcInteger}(node.handle), Int64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function Base.minimum(node::GcNode{<:Integer})
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_min(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function Base.maximum(node::GcNode{<:Integer})
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_max(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function increment(node::GcNode{<:Integer})
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_integer_get_inc(Ptr{LibAravis.ArvGcInteger}(node.handle), err)
    _throw_if_gerror!(err)
    return Int64(value)
end

function _float_value_unsafe(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_value(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function _float_value_unsafe!(node::GcNode, value::Real)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_float_set_value(Ptr{LibAravis.ArvGcFloat}(node.handle), Float64(value), err)
    _throw_if_gerror!(err)
    return nothing
end

function Base.minimum(node::GcNode{<:AbstractFloat})
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_min(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function Base.maximum(node::GcNode{<:AbstractFloat})
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_max(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function increment(node::GcNode{<:AbstractFloat})
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_float_get_inc(Ptr{LibAravis.ArvGcFloat}(node.handle), err)
    _throw_if_gerror!(err)
    return Float64(value)
end

function _bool_value_unsafe(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    value = LibAravis.arv_gc_boolean_get_value(Ptr{LibAravis.ArvGcBoolean}(node.handle), err)
    _throw_if_gerror!(err)
    return value != 0
end

function _bool_value_unsafe!(node::GcNode, value::Bool)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    LibAravis.arv_gc_boolean_set_value(Ptr{LibAravis.ArvGcBoolean}(node.handle), value ? 1 : 0, err)
    _throw_if_gerror!(err)
    return nothing
end

function _string_value_unsafe(node::GcNode)
    err = Ref{Ptr{LibAravis.GError}}(C_NULL)
    ptr = LibAravis.arv_gc_string_get_value(Ptr{LibAravis.ArvGcString}(node.handle), err)
    _throw_if_gerror!(err)
    ptr == C_NULL && return ""
    return unsafe_string(ptr)
end

function _string_value_unsafe!(node::GcNode, value::AbstractString)
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

Base.convert(::Type{Bool}, node::GcNode{Bool}) = value(node)
Base.convert(::Type{T}, node::GcNode{<:Integer}) where {T<:Integer} = convert(T, value(node))
Base.convert(::Type{T}, node::GcNode{<:AbstractFloat}) where {T<:AbstractFloat} = convert(T, value(node))
Base.convert(::Type{String}, node::GcNode{Any}) = as_string(node)
Base.convert(::Type{String}, node::GcNode{T}) where {T} = string(value(node))
