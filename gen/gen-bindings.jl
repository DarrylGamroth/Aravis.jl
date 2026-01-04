using Clang.Generators

using Aravis_jll
using Glib_jll

cd(@__DIR__)

include_root = joinpath(Aravis_jll.artifact_dir, "include")
include_dir = joinpath(include_root, "aravis-0.8")
if !isdir(include_dir)
    include_dir = include_root
end

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()
push!(args, "-I$include_dir")

glib_include = joinpath(Glib_jll.artifact_dir, "include", "glib-2.0")
glib_lib_include = joinpath(Glib_jll.artifact_dir, "lib", "glib-2.0", "include")
push!(args, "-I$glib_include")
push!(args, "-I$glib_lib_include")

headers = [
    joinpath(include_dir, "arv.h"),
]

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
