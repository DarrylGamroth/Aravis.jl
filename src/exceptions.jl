struct AravisError <: Exception
    domain::LibAravis.GQuark
    code::Cint
    message::String
end

Base.showerror(io::IO, err::AravisError) = print(io, "Aravis error ($(err.domain)): $(err.code) - $(err.message)")

function _throw_if_gerror!(err::Ref{Ptr{LibAravis.GError}})
    ptr = err[]
    ptr == C_NULL && return
    gerr = unsafe_load(ptr)
    msg = gerr.message == C_NULL ? "" : unsafe_string(gerr.message)
    GLib.g_error_free(ptr)
    err[] = C_NULL
    throw(AravisError(gerr.domain, gerr.code, msg))
end
