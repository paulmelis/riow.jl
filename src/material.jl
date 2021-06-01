struct ShadingInfo
    scattered::Ray
    attenuation::vec3
end

struct Lambertian
    albedo::color
end

function scatter(m::Lambertian, r_in::Ray, rec) ::Union{ShadingInfo,Nothing}

    scatter_direction = rec.normal + random_unit_vector()

    # Catch degenerate scatter direction
    if near_zero(scatter_direction)
        scatter_direction = rec.normal
    end

    return ShadingInfo(
        Ray(rec.p, scatter_direction),
        m.albedo)

end


struct Metal
    albedo::color
    fuzz::Float64
end

function scatter(m::Metal, r_in::Ray, rec) ::Union{ShadingInfo,Nothing}

    reflected = reflect(unit_vector(r_in.direction), rec.normal)
    direction = reflected + m.fuzz*random_in_unit_sphere()

    # XXX move the check to the beginning, so we don't compute unused values
    if dot(direction, rec.normal) <= 0
        return nothing
    end

    return ShadingInfo(
        Ray(rec.p, direction),
        m.albedo)

end


struct Dielectric
    ir::Float64     # Index of Refraction
end

function reflectance(cosine::Float64, ref_idx::Float64)
    # Use Schlick's approximation for reflectance.
    r0 = (1-ref_idx) / (1+ref_idx)
    r0 = r0*r0
    return r0 + (1-r0) * (1 - cosine) ^ 5
end

function scatter(m::Dielectric, r_in::Ray, rec) ::Union{ShadingInfo,Nothing}

    refraction_ratio = rec.front_face ? (1.0/m.ir) : m.ir

    unit_direction = unit_vector(r_in.direction)
    cos_theta = min(dot(-unit_direction, rec.normal), 1.0)
    sin_theta = sqrt(1.0 - cos_theta*cos_theta)

    cannot_refract = refraction_ratio * sin_theta > 1.0    

    if cannot_refract || (reflectance(cos_theta, refraction_ratio) > random_double())
        direction = reflect(unit_direction, rec.normal)
    else
        direction = refract(unit_direction, rec.normal, refraction_ratio)
    end

    return ShadingInfo(
        Ray(rec.p, direction),
        vec3(1.0, 1.0, 1.0))

end

const Material = Union{Lambertian, Metal, Dielectric}