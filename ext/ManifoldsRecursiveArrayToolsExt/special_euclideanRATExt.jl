function lie_bracket(G::SpecialEuclidean, X::ArrayPartition, Y::ArrayPartition)
    nX, hX = submanifold_components(G, X)
    nY, hY = submanifold_components(G, Y)
    return ArrayPartition(hX * nY - hY * nX, lie_bracket(G.manifold.manifolds[2], hX, hY))
end
function project(M::SpecialEuclideanInGeneralLinear, p)
    G = M.manifold
    np, hp = submanifold_components(G, p)
    return ArrayPartition(np, hp)
end
function project(M::SpecialEuclideanInGeneralLinear, p, X)
    G = M.manifold
    np, hp = submanifold_components(G, p)
    nX, hX = submanifold_components(G, X)
    return ArrayPartition(hp * nX, hX)
end

function exp(M::SpecialEuclidean, p::ArrayPartition, X::ArrayPartition)
    M1, M2 = M.manifold.manifolds
    return ArrayPartition(
        exp(M1.manifold, p.x[1], X.x[1]),
        exp(M2.manifold, p.x[2], X.x[2]),
    )
end
function log(M::SpecialEuclidean, p::ArrayPartition, q::ArrayPartition)
    M1, M2 = M.manifold.manifolds
    return ArrayPartition(
        log(M1.manifold, p.x[1], q.x[1]),
        log(M2.manifold, p.x[2], q.x[2]),
    )
end
function vee(M::SpecialEuclidean, p::ArrayPartition, X::ArrayPartition)
    M1, M2 = M.manifold.manifolds
    return vcat(vee(M1.manifold, p.x[1], X.x[1]), vee(M2.manifold, p.x[2], X.x[2]))
end
function get_coordinates(
    M::SpecialEuclidean,
    p::ArrayPartition,
    X::ArrayPartition,
    basis::DefaultOrthogonalBasis,
)
    M1, M2 = M.manifold.manifolds
    return vcat(
        get_coordinates(M1.manifold, p.x[1], X.x[1], basis),
        get_coordinates(M2.manifold, p.x[2], X.x[2], basis),
    )
end
function hat(
    M::SpecialEuclidean{TypeParameter{Tuple{2}}},
    p::ArrayPartition,
    c::AbstractVector,
)
    M1, M2 = M.manifold.manifolds
    return ArrayPartition(
        get_vector_orthogonal(M1.manifold, p.x[1], c[SOneTo(2)], ℝ),
        get_vector_orthogonal(M2.manifold, p.x[2], c[SA[3]], ℝ),
    )
end
function get_vector(
    M::SpecialEuclidean{TypeParameter{Tuple{2}}},
    p::ArrayPartition,
    c::AbstractVector,
    basis::DefaultOrthogonalBasis,
)
    return ArrayPartition(
        get_vector(M.manifold.manifolds[1].manifold, p.x[1], c[SOneTo(2)], basis),
        get_vector(M.manifold.manifolds[2].manifold, p.x[2], c[SA[3]], basis),
    )
end

function hat(
    M::SpecialEuclidean{TypeParameter{Tuple{3}}},
    p::ArrayPartition,
    c::AbstractVector,
)
    M1, M2 = M.manifold.manifolds
    return ArrayPartition(
        get_vector_orthogonal(M1.manifold, p.x[1], c[SOneTo(3)], ℝ),
        get_vector_orthogonal(M2.manifold, p.x[2], c[SA[4, 5, 6]], ℝ),
    )
end
function get_vector(
    M::SpecialEuclidean{TypeParameter{Tuple{3}}},
    p::ArrayPartition,
    c::AbstractVector,
    basis::DefaultOrthogonalBasis,
)
    return ArrayPartition(
        get_vector(M.manifold.manifolds[1].manifold, p.x[1], c[SOneTo(3)], basis),
        get_vector(M.manifold.manifolds[2].manifold, p.x[2], c[SA[4, 5, 6]], basis),
    )
end
function compose(::SpecialEuclidean, p::ArrayPartition, q::ArrayPartition)
    return ArrayPartition(p.x[2] * q.x[1] + p.x[1], p.x[2] * q.x[2])
end