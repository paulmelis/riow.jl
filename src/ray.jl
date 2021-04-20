mutable struct Ray

    origin::point3
    direction::vec3
    time::Float64

    Ray() = new()
    Ray(origin, direction) = new(origin, direction)
    Ray(origin, direction, time) = new(origin, direction, time)

end

at(r::Ray, t::Float64) = r.origin + t*r.direction
