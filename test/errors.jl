@testset "Aravis error handling" begin
    @test_throws ArgumentError open_camera(999)

    cam = open_camera()
    try
        dev = device(cam)
        @test_throws Aravis.AravisError integer_feature_value(dev, "NoSuchFeature")
    finally
        close(cam)
    end
end
