abstract type Material end

mutable struct HitRecord
    p::point3
    normal::vec3
    mat::Material
    t::Float64
    front_face::Bool

    HitRecord() = new()    
end

function set_face_normal!(rec::HitRecord, r::Ray, outward_normal::vec3)
    rec.front_face = dot(r.direction, outward_normal) < 0
    rec.normal = rec.front_face ? outward_normal : -outward_normal
end
