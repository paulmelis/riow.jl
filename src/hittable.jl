abstract type Hittable end

function hit(objects::Vector{Hittable}, r::Ray, t_min::Float64, t_max::Float64, rec::HitRecord)

    temp_rec = HitRecord()
    hit_anything = false
    closest_so_far = t_max

    for object in objects
        if hit(object, r, t_min, closest_so_far, temp_rec)
            hit_anything = true
            closest_so_far = temp_rec.t

            rec.p = temp_rec.p
            rec.normal = temp_rec.normal
            rec.mat = temp_rec.mat
            rec.t = temp_rec.t
            rec.front_face = temp_rec.front_face
        end
    end

    return hit_anything

end