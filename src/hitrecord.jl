struct HitRecord
    p::point3
    normal::vec3
    mat::Material
    t::Float64
    front_face::Bool
    
    function HitRecord(r::Ray, p::point3, outward_normal::vec3, mat::Material, t::Float64)
        front_face = dot(r.direction, outward_normal) < 0
        normal = front_face ? outward_normal : -outward_normal
        return new(p, normal, mat, t, front_face)
    end
end
