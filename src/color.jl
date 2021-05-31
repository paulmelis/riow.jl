function write_color(f, pixel_color::color, samples_per_pixel)

    r = pixel_color.x
    g = pixel_color.y
    b = pixel_color.z

    # Replace NaN components with zero. See explanation in Ray Tracing: The Rest of Your Life.
    # XXX
    if isnan(r) r = 0.0 end
    if isnan(g) g = 0.0 end
    if isnan(b) b = 0.0 end

    # Divide the color by the number of samples and gamma-correct for gamma=2.0.
    scale = 1.0 / samples_per_pixel
    r = sqrt(scale * r)
    g = sqrt(scale * g)
    b = sqrt(scale * b)

    # Write the translated [0,255] value of each color component.
    s = @sprintf("%d %d %d\n", 
        trunc(UInt8, 256 * clamp(r, 0.0, 0.999)),
        trunc(UInt8, 256 * clamp(g, 0.0, 0.999)),
        trunc(UInt8, 256 * clamp(b, 0.0, 0.999)))    
    write(f, s)

end
