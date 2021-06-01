struct Ray

    origin::point3
    direction::vec3
    time::Float64

    Ray() = new(point3(), vec3(), 0)
    Ray(o, d) = new(o, d, 0)
    Ray(o, d, t) = new(o, d, t)
    
end

at(r::Ray, t::Float64) = r.origin + t*r.direction
