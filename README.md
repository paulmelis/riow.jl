# Ray-tracing in One Weekend

A Julia implementation of Peter Shirley's [*Ray Tracing in One Weekend*](https://raytracing.github.io/books/RayTracingInOneWeekend.html).

Note that this was one of my first projects in Julia, 
hence not everything follows conventions (especially w.r.t. 
packaging). 

Plus, there's probably a lot of optimizations that can still be done.

Comparison with the C++ version:

* 1200x675 pixels, 10 samples per pixel, max ray depth 50
* Time to render on a Intel Core i5-4460 @ 3.20GHz:
    * C++ (GCC 11.1.0): 59.354s
    * Julia 1.7: 83.867s (`@btime`, i.e. excluding time for compilation)

## Notes

* Fairly straight-forward port from the C++ code, but with some 
  tweaks to make it fit Julia better.
* Not multi-threaded (yet)
