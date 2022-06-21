# 1.8+
#GC.enable_logging(true)

using StaticArrays
using Random
using Distributions
using LinearAlgebra
using Printf
using BenchmarkTools
using ArgParse
using Profile
#using ProfileView
using LoopVectorization

include("vec3.jl")
include("rtweekend.jl")
include("ray.jl")
include("material.jl")
include("hitrecord.jl")
include("color.jl")
include("camera.jl")
include("sphere.jl")
include("hittable.jl")
include("scene.jl")
include("raycolor.jl")

function main(fname, image_width, image_height, samples, max_depth)

    t0 = time()

    Random.seed!(123456)

    # Image

    aspect_ratio = image_width / image_height

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

    write(f, "P3\n$(image_width) $(image_height)\n255\n")

    for j = image_height-1:-1:0
        write(stderr, "\rScanlines remaining: $(j) ")
        for i = 0:image_width-1
            pixel_color = color(0,0,0)
            for s = 1:samples
                u = (i + rand()) / (image_width-1)
                v = (j + rand()) / (image_height-1)
                r = get_ray(cam, u, v)
                pixel_color += ray_color(r, world, max_depth)
                #pixel_color += ray_color_nonrecursive(r, world, max_depth)                
            end
            write_color(f, pixel_color, samples)
        end
    end

    t1 = time()

    write(stderr, "\nDone in $(t1-t0) seconds\n")

end

function parse_commandline()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--resolution", "-r"
            help = "Image resolution, <w>x<h>"
            default = "1200x675"
        "--samples", "-s"
            help = "Samples per pixel"
            arg_type = Int
            default = 10
        "--depth", "-d"
            help = "Path depth"
            arg_type = Int
            default = 50
        "--profile", "-p"
            help = "Run under profiler"
            action = :store_true       
        "--malloc-data", "-m"
            help = "Track allocations"
            action = :store_true       
         "--time", "-t"
            help = "Run under @time"
            action = :store_true            
        "--btime", "-b"
            help = "Run under @btime"
            action = :store_true            
        "filename"
            help = "Output image"
            default = "image.ppm"
            required = false
    end

    return parse_args(s)

end

if (!isinteractive())

    parsed_args = parse_commandline()

    #using InteractiveUtils
    #code_warntype(hit, (Vector{Hittable}, Ray, Float64, Float64))
    #doh()

    output_file = parsed_args["filename"]
    width, height = parse.(Int, split(parsed_args["resolution"], 'x'))
    samples = parsed_args["samples"]
    depth = parsed_args["depth"]

    if parsed_args["profile"]
        println("Running under profiler")
        #@profview main(output_file, width, height, samples, depth)
        @profile main(output_file, width, height, samples, depth)

        open("profile.txt", "w") do f
            #Profile.print(IOContext(f, :displaysize => (24, 500)), format=:tree, sortedby=:count)
            Profile.print(IOContext(f, :displaysize => (24, 500)), format=:flat, sortedby=:count)
            #Profile.print(IOContext(f, :displaysize => (24, 500)), format=:flat, sortedby=:overhead)
        end
    elseif parsed_args["btime"]
        println("Running under @btime")
        @btime main(output_file, width, height, samples, depth)
    elseif parsed_args["time"]
        println("Running under @time")
        @time main(output_file, width, height, samples, depth)
    elseif parsed_args["malloc-data"]
        println("Gathering malloc data (running twice), but don't forget --track-allocation=user")
        main(output_file, width, height, samples, depth)
        Profile.clear_malloc_data()
        main(output_file, width, height, samples, depth)
    else
        main(output_file, width, height, samples, depth)
    end

end