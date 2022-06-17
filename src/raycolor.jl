function ray_color(r::Ray, world::Vector{Hittable}, depth) ::color

    # If we've exceeded the ray bounce limit, no more light is gathered.
    if depth <= 0
        return color(0,0,0)
    end
    
    rec = hit(world, r, 0.001, Inf)

    if rec != nothing        
        s = scatter(rec.mat, r, rec)
        if s != nothing
            return s.attenuation * ray_color(s.scattered, world, depth-1)
        end
        return color(0,0,0)
    end

    # Return background color (which is a gradient in Y) when no scene object is hit
    unit_direction = unit_vector(r.direction)
    t = 0.5*(unit_direction.y + 1.0)
    return (1.0-t)*color(1.0, 1.0, 1.0) + t*color(0.5, 0.7, 1.0)

end

# XXX not fully equivalent yet
function ray_color_nonrecursive(r::Ray, world::Vector{Hittable}, depth) ::color
    
    # Need copy as we're modifying it
    ray = Ray(r.origin, r.direction)

    final_color = color(1, 1, 1)
    while depth > 0

        rec = hit(world, ray, 0.001, Inf)
        if rec != nothing
            s = scatter(rec.mat, ray, rec) 
            if s != nothing
                final_color *= s.attenuation

                ray = Ray(s.scattered.origin, s.scattered.direction)

                depth -= 1

                continue
            end

            break
        end

        # Nothing hit, use background color (which is a gradient in Y)
        unit_direction = unit_vector(ray.direction)
        t = 0.5*(unit_direction.y + 1.0)
        bgcolor = (1.0-t)*color(1.0, 1.0, 1.0) + t*color(0.5, 0.7, 1.0)
        final_color *= bgcolor

        break

    end

    # If we've exceeded the ray bounce limit, no more light is gathered.
    return final_color    

end
