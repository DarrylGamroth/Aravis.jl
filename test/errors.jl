@testset "Aravis error handling" begin
    @test_throws ArgumentError open_camera(999)

    cam = open_camera()
    try
        dev = device(cam)
        @test_throws Aravis.AravisError integer_feature_value(dev, "NoSuchFeature")

        gc = genicam(dev)
        width_node = node(gc, "Width")
        @test_throws MethodError string_value(width_node)
        typed_width = GcNode(Int, width_node)
        @test typed_width[Int] == integer_value(width_node)
    finally
        close(cam)
    end
end
