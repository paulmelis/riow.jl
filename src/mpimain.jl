# 1.8+
#GC.enable_logging(true)

using StaticArrays
using Random
using Distributions
using LinearAlgebra
using ArgParse
using Printf
using LoopVectorization
using ResumableFunctions
using ProgressMeter
using MPI

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
include("buckets.jl")

function root(comm, fname, image_width, image_height, samples, max_depth, bucket_size)

    num_workers = MPI.Comm_size(comm) - 1
    println("[0] Have $(num_workers) worker processes")

    t0 = time()

    aspect_ratio = image_width / image_height

    # XXX screw it, just turn the generator into the list it generates
    buckets = collect(buckets_reading_order(image_width, image_height, nothing, bucket_size))
    num_buckets = length(buckets)

    # World
    # XXX send world seed?

    # Camera

    config = (
        image_width = image_width,
        image_height = image_height,
        aspect_ratio = aspect_ratio,
        bucket_size = bucket_size,
        samples = samples,
        max_depth = max_depth,
        lookfrom = point3(13,2,3),
        lookat = point3(0,0,0),        
        vup = vec3(0,1,0),
        vfov = 20.0,
        dist_to_focus = 10.0,
        aperture = 0.1
    )    

    # Send config to workers

    MPI.bcast(config, 0, comm)

    # Continuously assign buckets to render to free workers, 
    # receive bucket pixel results, until all buckets done

    outstanding_requests = MPI.Request[]

    # Allocate arrays to receive works bucket pixels in
    worker_pixels = []    
    for i in 1:num_workers
        p = Array{Float64}(undef, bucket_size, bucket_size, 3)
        push!(worker_pixels, p)
    end
    worker_left = zeros(Int, num_workers)
    worker_top = zeros(Int, num_workers)

    # Allocate output image

    # zeros(..., rows, cols)
    image = zeros(Float64, image_height, image_width, 3)
    
    buckets_done = 0
    progress = Progress(num_buckets)

    # Bootstrap with initial bucket for each worker
    for worker in 1:num_workers

        if length(buckets) > 0            
            bucket = popfirst!(buckets)
            #println("[0] worker $(worker) initially gets $(bucket)")
            sreq = MPI.isend(bucket, worker, 0, comm)
            # XXX wait on this sreq?
            worker_left[worker] = bucket[1]
            worker_top[worker] = bucket[2]

            rreq = MPI.Irecv!(worker_pixels[worker], worker, 0, comm)
            push!(outstanding_requests, rreq)            
        else       
            # All buckets assigned                
            #println("[0] Not enough buckets to initially put all workers to work!")
            MPI.send(nothing, worker, 0, comm)
        end

    end

    while length(outstanding_requests) > 0
        #println("[0] -------")
        #println("[0] Have $(length(outstanding_requests)) outstanding requests")        

        # Wait for at least one rendered buckets from the workers
        index, status = MPI.Waitany!(outstanding_requests)
        #println("[0] index = $(index), status = $(status)")

        request = outstanding_requests[index]
        worker = status.source
        #println("[0] worker $(worker) returned pixels")        

        # XXX put pixels in image
        pixels = worker_pixels[worker]
        left = worker_left[worker]
        top = worker_top[worker]
        image[top+1:top+bucket_size, left+1:left+bucket_size, 1:3] = pixels

        next!(progress)

        deleteat!(outstanding_requests, index)        
        
        if length(buckets) > 0
            bucket = popfirst!(buckets)
            #println("[0] worker $(worker) now gets $(bucket)")
            sreq = MPI.isend(bucket, worker, 0, comm)
            # XXX wait on this sreq?
            worker_left[worker] = bucket[1]
            worker_top[worker] = bucket[2]

            rreq = MPI.Irecv!(worker_pixels[worker], worker, 0, comm)
            push!(outstanding_requests, rreq)
        else            
            #println("[0] All buckets assigned, worker $(worker) can stop")
            MPI.send(nothing, worker, 0, comm)            
        end

    end

    println("[0] All work done!")
    
    # Save image
    
    println("[0] Saving image")

    f = open(fname, "w")

    write(f, "P3\n$(image_width) $(image_height)\n255\n")

    for j = image_height:-1:1        
        for i = 1:image_width
            pixel_color = vec3(image[j,i,1], image[j,i,2], image[j,i,3])
            write_color(f, pixel_color, samples)
        end
    end

    t1 = time()

    write(stderr, "\nDone in $(t1-t0) seconds\n")

    MPI.Barrier(comm)
end


function worker(comm, rank)

    Random.seed!(123456)

    # Wait for scene setup data
    config = MPI.bcast(nothing, 0, comm)
    println("[$(rank)] $(config)")

    # Camera

    cam = Camera(config.lookfrom, config.lookat, config.vup, 
        config.vfov, config.aspect_ratio, config.aperture, config.dist_to_focus)

    samples::Int = config.samples
    max_depth::Int = config.max_depth
    image_width::Int = config.image_width
    image_height::Int = config.image_height
    max_bucket_size::Int = config.bucket_size

    # Set up our local copy of the scene
    # XXX base on seed from root?

    world = random_scene()    

    # Repeatedly wait for bucket and render it

    pixels = Array{Float64}(undef, max_bucket_size, max_bucket_size, 3)

    bucket, status = MPI.recv(0, 0, comm)
    #println("[$(rank)] Got $(bucket), $(status)")

    while bucket != nothing

        left::Int, top::Int, bucket_size::Int = bucket

        # Render bucket pixels    

        for j = 0:bucket_size-1
            for i = 0:bucket_size-1
                pixel_color = color(0,0,0)
                for s = 1:samples
                    u = (i + left + rand()) / (image_width-1)
                    v = (j + top + rand()) / (image_height-1)
                    r = get_ray(cam, u, v)
                    pixel_color += ray_color(r, world, max_depth)                    
                end
                pixels[j+1,i+1,1] = pixel_color.x
                pixels[j+1,i+1,2] = pixel_color.y
                pixels[j+1,i+1,3] = pixel_color.z
            end
        end

        # Return bucket pixels        
        #println("[$(rank)] Sending pixels")
        sreq = MPI.Isend(pixels, 0, 0, comm)
        #println("[$(rank)] Waiting for send to complete")
        MPI.Wait!(sreq)        
        #MPI.send(pixels, 0, 0, comm)
        
        # Get next bucket
        #println("[$(rank)] Getting next bucket")
        bucket, status = MPI.recv(0, 0, comm)
        #println("[$(rank)] Got $(bucket), $(status)")
    end

    # Our work is all done!

    MPI.Barrier(comm)
end

function parse_commandline()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--resolution", "-r"
            help = "Image resolution, <w>x<h>"
            #default = "1200x675"
            #default = "320x240"
            default = "1920x1080"
        "--samples", "-s"
            help = "Samples per pixel"
            arg_type = Int
            default = 10
        "--depth", "-d"
            help = "Path depth"
            arg_type = Int
            default = 5
        "--bucket", "-b"
            help = "Bucket size"
            arg_type = Int
            default = 20
        "filename"
            help = "Output image"
            default = "image.ppm"
            required = false
    end

    return parse_args(s)

end

if (!isinteractive())

    MPI.Init()
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    num_processes = MPI.Comm_size(comm)

    print("I am rank $(rank) of $(num_processes)\n")
    
    if rank == 0
        parsed_args = parse_commandline()

        output_file = parsed_args["filename"]
        width, height = parse.(Int, split(parsed_args["resolution"], 'x'))
        samples = parsed_args["samples"]
        depth = parsed_args["depth"]
        bucket_size = parsed_args["bucket"]

        root(comm, output_file, width, height, samples, depth, bucket_size)
    else
        worker(comm, rank)
    end

end