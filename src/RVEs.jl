module RVEs

using Gmsh: Gmsh, gmsh

export RVE
export Sphere
export Cylinder
export Ellipsoid
export Box
export Fuse
export Cut
export Intersect 
export createGmshModel
export stopGmsh
export startGmsh
export visualizeMesh
export createMesh!
export saveMesh
export ShowInfo


struct RVE
    size::Vector{Float64}    # size of the RVE
    periodicityFlags::Vector{Int64}       # periodicity flags
    origin::Vector{Float64}     # set cell origin to [0,0,0]
    meshsize::Float64
end
 

include("Inclusions.jl")
include("Periodicity.jl")
include("Utils.jl")


function _addBoundingBox!(model::Module, rve::RVE)
    model.occ.addBox(rve.origin[1], rve.origin[2], rve.origin[3], rve.size[1], rve.size[2], rve.size[3], 1)
    model.occ.synchronize()
end

function _isinboundary(rve::RVE, b::NTuple{6,Float64})
    xmin, ymin, zmin, xmax, ymax, zmax = _getBoundingBox(rve)
    out = false
    location = [0, 0, 0, 0, 0, 0]
    if b[1] <= xmin
        out = true
        location[1] = 1
    end
    if b[2] <= ymin
        out = true
        location[2] = 1
    end
    if b[3] <= zmin
        out = true
        location[3] = 1
    end
    if b[4] >= xmax
        out = true
        location[4] = 1
    end
    if b[5] >= ymax
        out = true
        location[5] = 1
    end
    if b[6] >= zmax
        out = true
        location[6] = 1
    end

    return out, location
end


function _getBoundingBox(rve::RVE)
    xmin = rve.origin[1]
    ymin = rve.origin[2]
    zmin = rve.origin[3]
    xmax = rve.origin[1] + rve.size[1]
    ymax = rve.origin[2] + rve.size[2]
    zmax = rve.origin[3] + rve.size[3]
    return [xmin, ymin, zmin, xmax, ymax, zmax]
end
 

function _addPhysicalGroups!(model::Module, out_::Vector{Any}, rve::RVE)
    xmin, ymin, zmin, xmax, ymax, zmax = _getBoundingBox(rve)
    eps = 1e-3

    allinc = vcat(out_[1:end-1]...)
    model.addPhysicalGroup(3, [out_[end][2]], 1, "Phase0")
    numinc = length(out_) - 1
    for i in 1:numinc
        model.addPhysicalGroup(3, map(x -> x[2], vcat(out_[i]...)), i + 2, "Phase$i")
    end
    model.addPhysicalGroup(3, map(x -> x[2], allinc), 2, "Inclusions")

    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmin + eps, ymax + eps, zmax + eps, 0)
    ent1 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmin + eps, ymax + eps, zmax + eps, 1)
    ent2 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmin + eps, ymax + eps, zmax + eps, 2)
    model.addPhysicalGroup(0, map(x -> x[2], ent0), 1, "Pointsxmin")
    model.addPhysicalGroup(1, map(x -> x[2], ent1), 1, "Linesxmin")
    model.addPhysicalGroup(2, map(x -> x[2], ent2), 1, "Surfxmin")

    ent0 = model.getEntitiesInBoundingBox(xmax - eps, ymin - eps, zmin - eps, xmax + eps, ymax + eps, zmax + eps, 0)
    ent1 = model.getEntitiesInBoundingBox(xmax - eps, ymin - eps, zmin - eps, xmax + eps, ymax + eps, zmax + eps, 1)
    ent2 = model.getEntitiesInBoundingBox(xmax - eps, ymin - eps, zmin - eps, xmax + eps, ymax + eps, zmax + eps, 2)
    model.addPhysicalGroup(0, map(x -> x[2], ent0), 2, "Pointsxmax")
    model.addPhysicalGroup(1, map(x -> x[2], ent1), 2, "Linesxmax")
    model.addPhysicalGroup(2, map(x -> x[2], ent2), 2, "Surfxmax")

    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmax + eps, ymin + eps, zmax + eps, 0)
    ent1 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmax + eps, ymin + eps, zmax + eps, 1)
    ent2 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmax + eps, ymin + eps, zmax + eps, 2)
    model.addPhysicalGroup(0, map(x -> x[2], ent0), 3, "Pointsymin")
    model.addPhysicalGroup(1, map(x -> x[2], ent1), 3, "Linesymin")
    model.addPhysicalGroup(2, map(x -> x[2], ent2), 3, "Surfymin")

    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymax - eps, zmin - eps, xmax + eps, ymax + eps, zmax + eps, 0)
    ent1 = model.getEntitiesInBoundingBox(xmin - eps, ymax - eps, zmin - eps, xmax + eps, ymax + eps, zmax + eps, 1)
    ent2 = model.getEntitiesInBoundingBox(xmin - eps, ymax - eps, zmin - eps, xmax + eps, ymax + eps, zmax + eps, 2)
    model.addPhysicalGroup(0, map(x -> x[2], ent0), 4, "Pointsymax")
    model.addPhysicalGroup(1, map(x -> x[2], ent1), 4, "Linesymax")
    model.addPhysicalGroup(2, map(x -> x[2], ent2), 4, "Surfymax")


    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmax + eps, ymax + eps, zmin + eps, 0)
    ent1 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmax + eps, ymax + eps, zmin + eps, 1)
    ent2 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmax + eps, ymax + eps, zmin + eps, 2)
    model.addPhysicalGroup(0, map(x -> x[2], ent0), 5, "Pointszmin")
    model.addPhysicalGroup(1, map(x -> x[2], ent1), 5, "Lineszmin")
    model.addPhysicalGroup(2, map(x -> x[2], ent2), 5, "Surfzmin")


    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmax - eps, xmax + eps, ymax + eps, zmax + eps, 0)
    ent1 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmax - eps, xmax + eps, ymax + eps, zmax + eps, 1)
    ent2 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmax - eps, xmax + eps, ymax + eps, zmax + eps, 2)
    model.addPhysicalGroup(0, map(x -> x[2], ent0), 6, "Pointszmax")
    model.addPhysicalGroup(1, map(x -> x[2], ent1), 6, "Lineszmax")
    model.addPhysicalGroup(2, map(x -> x[2], ent2), 6, "Surfzmax")

    corners = []
    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmin + eps, ymin + eps, zmin + eps, 0)
    push!(corners, map(x -> x[2], ent0))
    ent0 = model.getEntitiesInBoundingBox(xmax - eps, ymin - eps, zmin - eps, xmax + eps, ymin + eps, zmin + eps, 0)
    push!(corners, map(x -> x[2], ent0))
    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymax - eps, zmin - eps, xmin + eps, ymax + eps, zmin + eps, 0)
    push!(corners, map(x -> x[2], ent0))
    ent0 = model.getEntitiesInBoundingBox(xmax - eps, ymax - eps, zmin - eps, xmax + eps, ymax + eps, zmin + eps, 0)
    push!(corners, map(x -> x[2], ent0))
    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmax - eps, xmin + eps, ymin + eps, zmax + eps, 0)
    push!(corners, map(x -> x[2], ent0))
    ent0 = model.getEntitiesInBoundingBox(xmax - eps, ymin - eps, zmax - eps, xmax + eps, ymin + eps, zmax + eps, 0)
    push!(corners, map(x -> x[2], ent0))
    ent0 = model.getEntitiesInBoundingBox(xmin - eps, ymax - eps, zmax - eps, xmin + eps, ymax + eps, zmax + eps, 0)
    push!(corners, map(x -> x[2], ent0))
    ent0 = model.getEntitiesInBoundingBox(xmax - eps, ymax - eps, zmax - eps, xmax + eps, ymax + eps, zmax + eps, 0)
    push!(corners, map(x -> x[2], ent0))

    model.addPhysicalGroup(0, vcat(corners...), 7, "Corners")

end


function _findMatrixVolume(out_::Vector{Vector{Tuple{Int32, Int32}}})
    out_raw=out_[1]
    out_raw_=vcat(out_[2:end]...)
    out_matrix=[]
    out_inclusion=[]
    for j in  out_raw
        if  !(j in out_raw_)
            out_matrix=j
        else
            push!(out_inclusion, j)
        end
    end
    return out_matrix, out_inclusion
end


function createGmshModel(rve::RVE, inclusion::Inclusion ,name::String)
    return createGmshModel(rve, (inclusion, ), name)
end


function createGmshModel(rve::RVE, inclusions::Tuple, name::String)

    gmsh.model.add(name)
    xmin, ymin, zmin, xmax, ymax, zmax = _getBoundingBox(rve)
    _addBoundingBox!(gmsh.model, rve)
    dim3::Int32 = 3
    numinc = length(inclusions)
    _tags = Vector{Vector{Tuple{Int32,Int32}}}()
    push!(_tags, [(3, 1)])

    _numinc = zeros(Int32, numinc)
    for i in 1:numinc
        tag = inclusions[i](gmsh.model)
        inc_boundingbox = gmsh.model.occ.getBoundingBox(dim3, tag)
        isinboundary, boundarytype = _isinboundary(rve, inc_boundingbox)
        if isinboundary
            println("Inclusion $i is in the boundary!")
            __tags = _addPeriodicInclusions!(gmsh.model, rve, [(dim3, tag)], boundarytype)
            _numinc[i] = length(__tags)
            push!(_tags, __tags)
        else
            push!(_tags, [(dim3, tag)])
            _numinc[i] = 1
        end
    end

    out_ = []
     _, out__ = gmsh.model.occ.fragment(_tags[1], vcat(_tags[2]...))
     out_matrix, out_inc= _findMatrixVolume(out__)   
     push!(out_, out_inc)

      for i in 2:numinc
          _, out__ = gmsh.model.occ.fragment(out_matrix, vcat(_tags[i+1]...))
        out_matrix, out_inc= _findMatrixVolume(out__)   
        if length(out__[1])>1
            push!(out_, out_inc)
        end
      end
     push!(out_, out_matrix)
  
     gmsh.model.occ.synchronize()
     removol = gmsh.model.getEntities(3)

    gmsh.option.setNumber("Geometry.OCCBoundsUseStl", 1)
    eps = 1e-3
    vin = gmsh.model.getEntitiesInBoundingBox(xmin - eps, ymin - eps, zmin - eps, xmax + eps, ymax + eps, zmax + eps, 3)
    for v in vin
        deleteat!(removol, findall(x -> x == v, removol))
    end
    gmsh.model.removeEntities(removol, true)

     _addPhysicalGroups!(gmsh.model, out_, rve)

    return gmsh.model, out_
end

function createMesh!(model::Module, rve::RVE, inclusion::Inclusion, out_::Vector{Any})
    return createMesh!(model, rve, (inclusion,), out_)
end

function createMesh!(model::Module, rve::RVE, inclusions::Tuple, out_::Vector{Any})
    box = _getBoundingBox(rve)
    eps = 1e-3
 
    field_list=[]
    incu = 1
    taginc = model.getEntitiesForPhysicalGroup(3, incu)
    model.mesh.field.add("MathEval", 1)
    model.mesh.field.setString(1, "F",
        "$(rve.meshsize)")
    model.mesh.field.add("Restrict", 2)
    model.mesh.field.setNumber(2, "InField", 1)
    model.mesh.field.setNumbers(2, "VolumesList", vcat(taginc...))
    push!(field_list,2)
    
    numfield = 2
    for i in 1:length(out_)-1
        taginc = model.getEntitiesForPhysicalGroup(3, i + 2)
        tagdown = []
        for j in 1:length(taginc)
            _, tagdown_ = model.getAdjacencies(3, taginc[j])
            push!(tagdown, tagdown_)
        end

        lc=_getlc(inclusions[i])
        ref=inclusions[i].refinementwidth  
        meshsize=2*pi*lc/15

        numfield += 1
        model.mesh.field.add("MathEval", numfield)
        model.mesh.field.setString(numfield, "F",
            "$(meshsize/ref)")
        numfield += 1
        model.mesh.field.add("Restrict", numfield)
        model.mesh.field.setNumber(numfield, "InField", numfield - 1)
        # model.mesh.field.setNumbers(numfield, "VolumesList", vcat(taginc...))
         model.mesh.field.setNumbers(numfield, "SurfacesList", vcat(tagdown...))
        push!(field_list,numfield)
    
        numfield += 1
        model.mesh.field.add("Distance", numfield)
        model.mesh.field.setNumbers(numfield, "SurfacesList", vcat(tagdown...))
        model.mesh.field.setNumber(numfield, "Sampling", 100)
    
        numfield += 1
        model.mesh.field.add("Threshold", numfield)
        model.mesh.field.setNumber(numfield, "InField", numfield-1)
        model.mesh.field.setNumber(numfield, "SizeMin", meshsize/ref)
        model.mesh.field.setNumber(numfield, "SizeMax", rve.meshsize)
        model.mesh.field.setNumber(numfield, "DistMin", lc / 5)
        model.mesh.field.setNumber(numfield, "DistMax", lc / 2.5)
        push!(field_list,numfield)
    end
    
    
    numfield += 1
    model.mesh.field.add("Min", numfield)
    model.mesh.field.setNumbers(numfield, "FieldsList", field_list)
    model.mesh.field.setAsBackgroundMesh(numfield)
    
    gmsh.option.setNumber("Mesh.MeshSizeExtendFromBoundary", 0)
    gmsh.option.setNumber("Mesh.MeshSizeFromPoints", 0)
    gmsh.option.setNumber("Mesh.MeshSizeFromCurvature", 0)
    


    sxmin = model.getEntitiesInBoundingBox(box[1] - eps, box[2] - eps, box[3] - eps,
        box[4] + eps, box[5] + eps, box[6] + eps, 2)

    if rve.periodicityFlags[1] == 1
        for i in sxmin
            # Then we get the bounding box of each left surface
            xmin, ymin, zmin, xmax, ymax, zmax = model.getBoundingBox(i[1], i[2])
            # We translate the bounding box to the right and look for surfaces inside
            # it:
            sxmax = model.getEntitiesInBoundingBox(xmin - eps + rve.size[1], ymin - eps,
                zmin - eps, xmax + eps + rve.size[1],
                ymax + eps, zmax + eps, 2)
            # For all the matches, we compare the corresponding bounding boxes...
            for j in sxmax
                xmin2, ymin2, zmin2, xmax2, ymax2, zmax2 = model.getBoundingBox(
                    j[1], j[2])
                xmin2 -= rve.size[1]
                xmax2 -= rve.size[1]
                # ...and if they match, we apply the periodicity constraint
                if (abs(xmin2 - xmin) < eps && abs(xmax2 - xmax) < eps &&
                    abs(ymin2 - ymin) < eps && abs(ymax2 - ymax) < eps &&
                    abs(zmin2 - zmin) < eps && abs(zmax2 - zmax) < eps)
                    model.mesh.setPeriodic(2, [j[2]], [i[2]], [1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])
                end
            end
        end
    end

    if rve.periodicityFlags[2] == 1
        for i in sxmin
            # Then we get the bounding box of each left surface
            xmin, ymin, zmin, xmax, ymax, zmax = model.getBoundingBox(i[1], i[2])
            # We translate the bounding box to the right and look for surfaces inside
            # it:
            sxmax = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps + rve.size[2],
                zmin - eps, xmax + eps,
                ymax + eps + rve.size[2], zmax + eps, 2)
            # For all the matches, we compare the corresponding bounding boxes...
            for j in sxmax
                xmin2, ymin2, zmin2, xmax2, ymax2, zmax2 = model.getBoundingBox(
                    j[1], j[2])
                ymin2 -= rve.size[2]
                ymax2 -= rve.size[2]
                # ...and if they match, we apply the periodicity constraint
                if (abs(xmin2 - xmin) < eps && abs(xmax2 - xmax) < eps &&
                    abs(ymin2 - ymin) < eps && abs(ymax2 - ymax) < eps &&
                    abs(zmin2 - zmin) < eps && abs(zmax2 - zmax) < eps)
                    model.mesh.setPeriodic(2, [j[2]], [i[2]], [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1])
                end
            end
        end
    end

    if rve.periodicityFlags[3] == 1
        for i in sxmin
            # Then we get the bounding box of each left surface
            xmin, ymin, zmin, xmax, ymax, zmax = model.getBoundingBox(i[1], i[2])
            # We translate the bounding box to the right and look for surfaces inside
            # it:
            sxmax = model.getEntitiesInBoundingBox(xmin - eps, ymin - eps,
                zmin - eps + rve.size[3], xmax + eps,
                ymax + eps, zmax + eps + rve.size[3], 2)
            # For all the matches, we compare the corresponding bounding boxes...
            for j in sxmax
                xmin2, ymin2, zmin2, xmax2, ymax2, zmax2 = model.getBoundingBox(
                    j[1], j[2])
                zmin2 -= rve.size[3]
                zmax2 -= rve.size[3]
                # ...and if they match, we apply the periodicity constraint
                if (abs(xmin2 - xmin) < eps && abs(xmax2 - xmax) < eps &&
                    abs(ymin2 - ymin) < eps && abs(ymax2 - ymax) < eps &&
                    abs(zmin2 - zmin) < eps && abs(zmax2 - zmax) < eps)
                    model.mesh.setPeriodic(2, [j[2]], [i[2]], [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1])
                end
            end
        end
    end

    model.mesh.generate(3)
 
    return model
end
 

end
