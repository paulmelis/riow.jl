struct Sphere <: Hittable
    center::point3
    radius::Float64
    mat::Material

    Sphere() = new()
    Sphere(center, radius, mat) = new(center, radius, mat)
end

function hit(s::Sphere, r::Ray, t_min::Float64, t_max::Float64, rec::HitRecord)

    oc = r.origin - s.center
    a = length_squared(r.direction)
    half_b = dot(oc, r.direction)
    c = length_squared(oc) - s.radius*s.radius

    discriminant = half_b*half_b - a*c
    if discriminant < 0 
        return false
    end
    sqrtd = sqrt(discriminant)

    # Find the nearest root that lies in the acceptable range.
    root = (-half_b - sqrtd) / a
    if root < t_min || t_max < root
        root = (-half_b + sqrtd) / a
        if root < t_min || t_max < root
            return false
        end
    end

    rec.t = root
    rec.p = at(r, rec.t)
    outward_normal = (rec.p - s.center) / s.radius
    set_face_normal!(rec, r, outward_normal)
    rec.mat = s.mat

    return true

end