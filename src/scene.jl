function random_scene(seed=123456)

    Random.seed!(seed)

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
