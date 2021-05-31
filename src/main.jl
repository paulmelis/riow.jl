using StaticArrays
using Random
using Distributions
using LinearAlgebra
using Printf
using BenchmarkTools

include("vec3.jl")
include("rtweekend.jl")
include("ray.jl")
include("hitrecord.jl")
include("material.jl")
include("hittable.jl")
include("sphere.jl")
include("camera.jl")
include("color.jl")

function ray_color(r::Ray, world::Vector{Hittable}, depth) ::color

    # If we've exceeded the ray bounce limit, no more light is gathered.
    if depth <= 0
        return color(0,0,0)
    end
    
    rec = hit(world, r, 0.001, Inf)

    if rec != nothing
        s = ShadingInfo()
        if scatter(rec.mat, r, rec, s)
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
    
    ray = Ray()
    ray.origin = r.origin
    ray.direction = r.direction

    final_color = color(1, 1, 1)
    rec = HitRecord()
    s = ShadingInfo()

    while depth > 0

        if hit(world, ray, 0.001, Inf, rec)            
            if scatter(rec.mat, ray, rec, s)
                final_color *= s.attenuation

                ray.origin = s.scattered.origin
                ray.direction = s.scattered.direction

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



function random_scene()
    world = Vector{Hittable}()

    ground_material = Lambertian(color(0.5, 0.5, 0.5))
    push!(world, Sphere(point3(0,-1000,0), 1000, ground_material))

    for a in -11:11
        for b in -11:11
        
            choose_mat = random_double()
            center = point3(a + 0.9*random_double(), 0.2, b + 0.9*random_double())

            if norm(center - point3(4, 0.2, 0)) > 0.9                

                if choose_mat < 0.8
                    # diffuse
                    albedo = random(color) * random(color)
                    sphere_material = Lambertian(albedo)                
                elseif choose_mat < 0.95
                    # metal
                    albedo = random(color, 0.5, 1.0)
                    fuzz = random_double(0, 0.5)
                    sphere_material = Metal(albedo, fuzz)                    
                else
                    # glass
                    sphere_material = Dielectric(1.5)
                end

                push!(world, Sphere(center, 0.2, sphere_material))
            end
        end
    end
    
    material1 = Dielectric(1.5)
    push!(world, Sphere(point3(0, 1, 0), 1.0, material1))

    material2 = Lambertian(color(0.4, 0.2, 0.1))
    push!(world, Sphere(point3(-4, 1, 0), 1.0, material2))
    
    material3 = Metal(color(0.7, 0.6, 0.5), 0.0)
    push!(world, Sphere(point3(4, 1, 0), 1.0, material3))

    return world
end

function main(fname, image_width)

    Random.seed!(123456)

    # Image

    aspect_ratio = 16.0 / 9.0
    #image_width = 120
    image_height = trunc(Int, image_width / aspect_ratio)
    samples_per_pixel = 10
    max_depth = 50

    # World

    world = random_scene()

    # Camera

    lookfrom = point3(13,2,3)
    lookat = point3(0,0,0)
    vup = vec3(0,1,0)
    dist_to_focus = 10.0
    aperture = 0.1

    cam = Camera(lookfrom, lookat, vup, 20.0, aspect_ratio, aperture, dist_to_focus)

    # Render
    
    f = open(fname, "w")
    r = Ray()

    t0 = time()

    write(f, "P3\n$(image_width) $(image_height)\n255\n")

    for j = image_height-1:-1:0
        write(stderr, "\rScanlines remaining: $(j) ")
        for i = 0:image_width-1
            pixel_color = color(0,0,0)
            for s = 1:samples_per_pixel
                u = (i + rand()) / (image_width-1)
                v = (j + rand()) / (image_height-1)
                get_ray(cam, r, u, v)
                pixel_color += ray_color(r, world, max_depth)
            end
            write_color(f, pixel_color, samples_per_pixel)
        end
    end

    t1 = time()

    write(stderr, "\nDone in $(t1-t0) seconds\n")

end

const output_file = ARGS[1]

#@btime main($output_file, 120)
#@time main(output_file, 120)
main(output_file, 120)
#main(output_file, 512)