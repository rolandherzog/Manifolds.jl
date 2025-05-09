@doc raw"""
    LogCholeskyMetric <: RiemannianMetric

The Log-Cholesky metric imposes a metric based on the Cholesky decomposition as
introduced by [Lin:2019](@cite).
"""
struct LogCholeskyMetric <: RiemannianMetric end

cholesky_to_spd(x, W) = (x * x', W * x' + x * W')

tangent_cholesky_to_tangent_spd!(x, W) = (W .= W * x' + x * W')

spd_to_cholesky(p, X) = spd_to_cholesky(p, cholesky(p).L, X)

function spd_to_cholesky(p, x, X)
    w = inv(x) * X * inv(transpose(x))
    # strictly lower triangular plus half diagonal
    return (x, x * (LowerTriangular(w) - Diagonal(w) / 2))
end

@doc raw"""
    distance(M::MetricManifold{SymmetricPositiveDefinite,LogCholeskyMetric}, p, q)

Compute the distance on the manifold of [`SymmetricPositiveDefinite`](@ref)
nmatrices, i.e. between two symmetric positive definite matrices `p` and `q`
with respect to the [`LogCholeskyMetric`](@ref). The formula reads

````math
d_{\mathcal P(n)}(p,q) = \sqrt{
 \lVert ⌊ x ⌋ - ⌊ y ⌋ \rVert_{\mathrm{F}}^2
 + \lVert \log(\operatorname{diag}(x)) - \log(\operatorname{diag}(y))\rVert_{\mathrm{F}}^2 }\ \ ,
````

where ``x`` and ``y`` are the Cholesky factors of ``p`` and ``q``, respectively,
``⌊⋅⌋`` denbotes the strictly lower triangular matrix of its argument,
and ``\lVert⋅\rVert_{\mathrm{F}}`` the Frobenius norm.
"""
function distance(M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric}, p, q)
    N = get_parameter(M.manifold.size)[1]
    return distance(
        CholeskySpace(N; parameter=get_parameter_type(M.manifold)),
        cholesky(p).L,
        cholesky(q).L,
    )
end

@doc raw"""
    exp(M::MetricManifold{SymmetricPositiveDefinite,LogCholeskyMetric}, p, X)

Compute the exponential map on the [`SymmetricPositiveDefinite`](@ref) `M` with
[`LogCholeskyMetric`](@ref) from `p` into direction `X`. The formula reads

````math
\exp_p X = (\exp_y W)(\exp_y W)^\mathrm{T}
````

where ``\exp_xW`` is the exponential map on [`CholeskySpace`](@ref), ``y`` is the Cholesky
decomposition of ``p``, ``W = y(y^{-1}Xy^{-\mathrm{T}})_\frac{1}{2}``,
and ``(⋅)_\frac{1}{2}``
denotes the lower triangular matrix with the diagonal multiplied by ``\frac{1}{2}``.
"""
exp(::MetricManifold{ℝ,SymmetricPositiveDefinite,LogCholeskyMetric}, ::Any, ::Any)

function exp!(M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric}, q, p, X)
    N = get_parameter(M.manifold.size)[1]
    (y, W) = spd_to_cholesky(p, X)
    z = exp(CholeskySpace(N; parameter=get_parameter_type(M.manifold)), y, W)
    return copyto!(q, z * z')
end
function exp_fused!(
    M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric},
    q,
    p,
    X,
    t::Number,
)
    return exp!(M, q, p, t * X)
end

function get_coordinates_orthonormal!(
    M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric},
    Xⁱ,
    p,
    X,
    rn::RealNumbers,
)
    N = get_parameter(M.manifold.size)[1]
    MC = CholeskySpace(N; parameter=get_parameter_type(M.manifold))
    (y, W) = spd_to_cholesky(p, X)
    get_coordinates_orthonormal!(MC, Xⁱ, y, W, rn)
    return Xⁱ
end

function get_vector_orthonormal!(
    M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric},
    X,
    p,
    Xⁱ,
    rn::RealNumbers,
)
    N = get_parameter(M.manifold.size)[1]
    MC = CholeskySpace(N; parameter=get_parameter_type(M.manifold))
    y = cholesky(p).L
    get_vector_orthonormal!(MC, X, y, Xⁱ, rn)
    tangent_cholesky_to_tangent_spd!(p, X)
    return X
end

@doc raw"""
    inner(M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric}, p, X, Y)

Compute the inner product of two matrices `X`, `Y` in the tangent space of `p`
on the [`SymmetricPositiveDefinite`](@ref) manifold `M`, as
a [`MetricManifold`](@ref) with [`LogCholeskyMetric`](@ref). The formula reads

````math
    g_p(X,Y) = ⟨a_z(X),a_z(Y)⟩_z,
````

where ``⟨⋅,⋅⟩_x`` denotes inner product on the [`CholeskySpace`](@ref),
``z`` is the Cholesky factor of ``p``,
``a_z(W) = z (z^{-1}Wz^{-\mathrm{T}})_{\frac{1}{2}}``, and ``(⋅)_\frac{1}{2}``
denotes the lower triangular matrix with the diagonal multiplied by ``\frac{1}{2}``
"""
function inner(M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric}, p, X, Y)
    N = get_parameter(M.manifold.size)[1]
    (z, Xz) = spd_to_cholesky(p, X)
    (z, Yz) = spd_to_cholesky(p, z, Y)
    return inner(CholeskySpace(N; parameter=get_parameter_type(M.manifold)), z, Xz, Yz)
end

"""
    is_flat(::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric})

Return true. [`SymmetricPositiveDefinite`](@ref) with [`LogCholeskyMetric`](@ref)
is a flat manifold. See Proposition 8 of [Lin:2019](@cite).
"""
is_flat(M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric}) = true

@doc raw"""
    log(M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric}, p, q)

Compute the logarithmic map on [`SymmetricPositiveDefinite`](@ref) `M` with
respect to the [`LogCholeskyMetric`](@ref) emanating from `p` to `q`.
The formula can be adapted from the [`CholeskySpace`](@ref) as
````math
\log_p q = xW^{\mathrm{T}} + Wx^{\mathrm{T}},
````
where ``x`` is the Cholesky factor of ``p`` and ``W=\log_x y`` for ``y`` the Cholesky factor
of ``q`` and the just mentioned logarithmic map is the one on [`CholeskySpace`](@ref).
"""
log(::MetricManifold{ℝ,SymmetricPositiveDefinite,LogCholeskyMetric}, ::Any...)

function log!(M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric}, X, p, q)
    N = get_parameter(M.manifold.size)[1]
    x = cholesky(p).L
    y = cholesky(q).L
    log!(CholeskySpace(N; parameter=get_parameter_type(M.manifold)), X, x, y)
    return tangent_cholesky_to_tangent_spd!(x, X)
end

@doc raw"""
    vector_transport_to(
        M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric},
        p,
        X,
        q,
        ::ParallelTransport,
    )

Parallel transport the tangent vector `X` at `p` along the geodesic to `q` with respect to
the [`SymmetricPositiveDefinite`](@ref) manifold `M` and [`LogCholeskyMetric`](@ref).
The parallel transport is based on the parallel transport on [`CholeskySpace`](@ref):
Let ``x`` and ``y`` denote the Cholesky factors of `p` and `q`, respectively and
``W = x(x^{-1}Xx^{-\mathrm{T}})_\frac{1}{2}``, where ``(⋅)_\frac{1}{2}`` denotes the lower
triangular matrix with the diagonal multiplied by ``\frac{1}{2}``. With ``V`` the parallel
transport on [`CholeskySpace`](@ref) from ``x`` to ``y``. The formula hear reads

````math
\mathcal P_{q←p}X = yV^{\mathrm{T}} + Vy^{\mathrm{T}}.
````
"""
parallel_transport_to(
    ::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric},
    ::Any,
    ::Any,
    ::Any,
)

function parallel_transport_to!(
    M::MetricManifold{ℝ,<:SymmetricPositiveDefinite,LogCholeskyMetric},
    Y,
    p,
    X,
    q,
)
    N = get_parameter(M.manifold.size)[1]
    y = cholesky(q).L
    (x, W) = spd_to_cholesky(p, X)
    parallel_transport_to!(
        CholeskySpace(N; parameter=get_parameter_type(M.manifold)),
        Y,
        x,
        W,
        y,
    )
    return tangent_cholesky_to_tangent_spd!(y, Y)
end
