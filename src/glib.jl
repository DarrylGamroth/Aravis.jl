module GLib

using Glib_jll
using ..LibAravis

const libgobject = Glib_jll.libgobject
const libglib = Glib_jll.libglib

function g_object_ref(obj::Ptr{Cvoid})::Ptr{Cvoid}
    @ccall libgobject.g_object_ref(obj::Ptr{Cvoid})::Ptr{Cvoid}
end

function g_object_unref(obj::Ptr{Cvoid})::Cvoid
    @ccall libgobject.g_object_unref(obj::Ptr{Cvoid})::Cvoid
end

function g_error_free(err::Ptr{LibAravis.GError})::Cvoid
    @ccall libglib.g_error_free(err::Ptr{LibAravis.GError})::Cvoid
end

function g_free(ptr::Ptr{Cvoid})::Cvoid
    @ccall libglib.g_free(ptr::Ptr{Cvoid})::Cvoid
end

function g_strfreev(strv::Ptr{Ptr{Cchar}})::Cvoid
    @ccall libglib.g_strfreev(strv::Ptr{Ptr{Cchar}})::Cvoid
end

end # module GLib
