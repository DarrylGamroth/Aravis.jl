using Clang.Generators

using Aravis_jll

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

headers = [
    joinpath(include_dir, "arv.h"),
]

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
