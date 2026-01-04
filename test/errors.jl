@testset "Aravis error handling" begin
    @test_throws ArgumentError open_camera(999)

    cam = open_camera()
    try
        dev = device(cam)
        @test_throws Aravis.AravisError integer_feature_value(dev, "NoSuchFeature")

        gc = genicam(dev)
        width_node = node(gc, "Width")
        @test_throws MethodError value!(width_node, "bad")
        @test width_node[Int] == value(width_node)
    finally
        close(cam)
    end
end
