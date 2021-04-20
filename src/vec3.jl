import Base.+, Base.-, Base.*, Base.^

mutable struct vec3 <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
    
    vec3() = new(0, 0, 0)
    vec3(x, y, z) = new(x, y, z)
end

function Base.show(io::IO, v::vec3)
    print(io, "<vec3 $(v.x) $(v.y) $(v.z)>")
end

+(v::vec3, w::vec3) = vec3(v.x+w.x, v.y+w.y, v.z+w.z)
-(v::vec3, w::vec3) = vec3(v.x-w.x, v.y-w.y, v.z-w.z)
*(v::vec3, f::AbstractFloat) = vec3(v.x*f, v.y*f, v.z*f)
*(f::AbstractFloat, v::vec3) = vec3(v.x*f, v.y*f, v.z*f)
# Note: NOT dot product
*(v::vec3, w::vec3) = vec3(v.x*w.x, v.y*w.y, v.z*w.z)

^(v::vec3, w::vec3) = vec3(
    v.y*w.z - v.z*w.y,
    v.z*w.x - v.x*w.z,
    v.x*w.y - v.y*w.x
)

color = vec3
point3 = vec3

unit_vector(v::vec3) = v / norm(v)
#normalized(v::vec3) = v / norm(v)
length_squared(v::vec3) = dot(v, v)

function random(::Type{vec3})
    return vec3(rand(), rand(), rand())
end

function random(::Type{vec3}, min::Float64, max::Float64)
    x = random_double(min,max)
    y = random_double(min,max)
    z = random_double(min,max)
    return vec3(x, y, z)
end

function near_zero(v::vec3)
    s = 1e-8
    return (abs(v.x) < s) && (abs(v.y) < s) && (abs(v.z) < s)
end

function random_in_unit_sphere()
    while true
        p = random(vec3, -1.0, 1.0)
        if (length_squared(p) >= 1) 
            continue
        end
        return p
    end
end

function random_in_unit_disk()
    while true
        p = vec3(random_double(-1.0,1.0), random_double(-1.0,1.0), 0)
        if length_squared(p) >= 1 
            continue
        end
        return p
    end
end


random_unit_vector() = unit_vector(random_in_unit_sphere())

reflect(v::vec3, n::vec3) = v - 2*dot(v,n)*n

function refract(uv::vec3, n::vec3, etai_over_etat::Float64)
    cos_theta = min(dot(-uv, n), 1.0)
    r_out_perp =  etai_over_etat * (uv + cos_theta*n)
    r_out_parallel = -sqrt(abs(1.0 - length_squared(r_out_perp))) * n
    return r_out_perp + r_out_parallel
end