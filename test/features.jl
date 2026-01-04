@testset "Aravis feature access" begin
    with_fake_camera() do
        cam = open_camera()
        try
            dev = device(cam)
            @test is_feature_available(dev, "Width")
            width = integer_feature_value(dev, "Width")
            bounds = integer_feature_bounds(dev, "Width")
            @test width >= bounds[1]
            @test width <= bounds[2]
            @test feature(dev, Int, "Width") == width

            gc = genicam(dev)
            width_node = node(gc, "Width")
            @test is_available(width_node)
            @test integer_value(width_node) == width
            @test width_node[Int] == width
        finally
            Aravis.close(cam)
        end
    end
end
