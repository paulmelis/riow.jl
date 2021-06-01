struct Camera    

    origin::point3
    lower_left_corner::point3
    horizontal::vec3
    vertical::vec3
    u::vec3
    v::vec3
    w::vec3
    lens_radius::Float64     
    time0::Float64          # shutter open/close times
    time1::Float64    
        
    Camera() = Camera(point3(0,0,-1), point3(0,0,0), vec3(0,1,0), 40, 1, 0, 10)

    # vfov = vertical field-of-view in degrees
    function Camera(lookfrom::point3, lookat::point3, vup::vec3, vfov::Float64, aspect_ratio::Float64, aperture::Float64, focus_dist::Float64, time0 = 0, time1 = 0)

        theta = deg2rad(vfov)
        h = tan(theta/2)        
        viewport_height = 2.0 * h        
        viewport_width = aspect_ratio * viewport_height

        w = unit_vector(lookfrom - lookat)
        u = unit_vector(vup ^ w)
        v = w ^ u

        origin = lookfrom
        horizontal = focus_dist * viewport_width * u
        vertical = focus_dist * viewport_height * v

        return new(
            origin,
            origin - horizontal/2 - vertical/2 - focus_dist*w,
            horizontal,
            vertical,
            u, v, w,
            aperture / 2, 
            time0, time1)

    end

end


function get_ray(c::Camera, s::Float64, t::Float64)
    rd = c.lens_radius * random_in_unit_disk()
    offset = c.u * rd.x + c.v * rd.y
    
    origin = c.origin + offset
    direction = c.lower_left_corner + s*c.horizontal + t*c.vertical - c.origin - offset
    t = random_double(c.time0, c.time1)

    return Ray(origin, direction, t)
end