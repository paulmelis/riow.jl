const Hittable = Union{Sphere}

function hit(objects::Vector{Hittable}, r::Ray, t_min::Float64, t_max::Float64) ::Union{HitRecord,Nothing}

    best_rec::Union{HitRecord,Nothing} = nothing
    closest_so_far = t_max

    for object in objects
        rec = hit(object, r, t_min, closest_so_far)
        if rec != nothing
            closest_so_far = rec.t
            best_rec = rec
        end
    end

    return best_rec

end