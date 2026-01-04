@testset "Aravis feature access" begin
    cam = open_camera()
    try
        dev = device(cam)
        @test is_feature_available(dev, "Width")
        width = integer_feature_value(dev, "Width")
        bounds = integer_feature_bounds(dev, "Width")
        @test width >= bounds[1]
        @test width <= bounds[2]
        @test feature(dev, Int, "Width") == width
        integer_feature_value!(dev, "Width", width)
        @test integer_feature_value(dev, "Width") == width

        @test is_feature_available(dev, "DeviceVendorName")
        vendor = string_feature_value(dev, "DeviceVendorName")
        @test !isempty(vendor)

        gc = genicam(dev)
        width_node = node(gc, "Width")
        @test is_available(width_node)
        @test integer_value(width_node) == width
        @test width_node[Int] == width
        value!(width_node, width)
    finally
        close(cam)
    end
end
