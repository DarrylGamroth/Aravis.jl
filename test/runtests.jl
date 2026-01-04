using Test

using Aravis
using Aravis.LibAravis
using Aravis_jll

include("helpers.jl")

with_fake_camera() do
    include("acquisition.jl")
    include("buffer_metadata.jl")
    include("config.jl")
    include("errors.jl")
    include("features.jl")
    include("allocations.jl")
end
