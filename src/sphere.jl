struct Sphere
    center::point3
    radius::Float64
    mat::Material

    Sphere() = new()
    Sphere(center, radius, mat) = new(center, radius, mat)
end

function hit(s::Sphere, r::Ray, t_min::Float64, t_max::Float64) ::Union{HitRecord,Nothing}

    oc = r.origin - s.center
    a = length_squared(r.direction)
    half_b = dot(oc, r.direction)
    c = length_squared(oc) - s.radius*s.radius

    discriminant = half_b*half_b - a*c
    if discriminant < 0 
        return nothing
    end
    sqrtd = sqrt(discriminant)

    # Find the nearest root that lies in the acceptable range.
    root = (-half_b - sqrtd) / a
    if root < t_min || t_max < root
        root = (-half_b + sqrtd) / a
        if root < t_min || t_max < root
            return nothing
        end
    end

    t = root
    p = at(r, t)
    n = (p - s.center) / s.radius
    outward_normal = (p - s.center) / s.radius
    
    return HitRecord(r, p, outward_normal, s.mat, t)

end
