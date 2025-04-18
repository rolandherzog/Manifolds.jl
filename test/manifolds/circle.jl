include("../header.jl")

using Manifolds: TFVector, CoTFVector

@testset "Circle" begin
    M = Circle()
    @testset "Real Circle Basics" begin
        @test repr(M) == "Circle(ℝ)"
        @test representation_size(M) == ()
        @test manifold_dimension(M) == 1
        @test is_flat(M)
        @test !is_point(M, 9.0)
        @test !is_point(M, zeros(3, 3))
        @test Manifolds.check_size(M, [9.0]) === nothing
        @test Manifolds.check_size(M, [1.0], [-2.0]) === nothing
        @test_throws DomainError is_point(M, 9.0; error=:error)
        @test_throws DomainError is_point(M, zeros(3, 3); error=:error)
        @test !is_vector(M, 9.0, 0.0)
        @test !is_vector(M, zeros(3, 3), zeros(3, 3))
        @test_throws DomainError is_vector(M, 9.0, 0.0; error=:error)
        @test_throws DomainError is_vector(M, zeros(3, 3), zeros(3, 3); error=:error)
        @test_throws DomainError is_vector(M, 0.0, zeros(3, 3); error=:error)
        @test is_vector(M, 0.0, 0.0)
        @test get_coordinates(M, Ref(0.0), Ref(2.0), DefaultOrthonormalBasis())[] ≈ 2.0
        @test get_coordinates(
            M,
            Ref(0.0),
            Ref(2.0),
            DiagonalizingOrthonormalBasis(Ref(1.0)),
        )[] ≈ 2.0
        @test get_coordinates(
            M,
            Ref(0.0),
            Ref(-2.0),
            DiagonalizingOrthonormalBasis(Ref(1.0)),
        )[] ≈ -2.0
        @test get_coordinates(
            M,
            Ref(0.0),
            Ref(2.0),
            DiagonalizingOrthonormalBasis(Ref(-1.0)),
        )[] ≈ -2.0
        @test get_coordinates(
            M,
            Ref(0.0),
            Ref(-2.0),
            DiagonalizingOrthonormalBasis(Ref(-1.0)),
        )[] ≈ 2.0
        y = [0.0]
        get_coordinates!(M, y, Ref(0.0), Ref(2.0), DiagonalizingOrthonormalBasis(Ref(1.0)))
        @test y ≈ [2.0]
        @test get_vector(M, Ref(0.0), [2.0], DefaultOrthonormalBasis())[] ≈ 2.0
        @test get_vector(M, [0.0], [2.0], DefaultOrthonormalBasis())[] ≈ 2.0
        @test get_vector(M, Ref(0.0), [2.0], DiagonalizingOrthonormalBasis(Ref(1.0)))[] ≈
              2.0
        @test get_vector(M, Ref(0.0), [-2.0], DiagonalizingOrthonormalBasis(Ref(1.0)))[] ≈
              -2.0
        @test get_vector(M, Ref(0.0), [2.0], DiagonalizingOrthonormalBasis(Ref(-1.0)))[] ≈
              -2.0
        @test get_vector(M, Ref(0.0), [-2.0], DiagonalizingOrthonormalBasis(Ref(-1.0)))[] ≈
              2.0
        @test number_of_coordinates(M, DiagonalizingOrthonormalBasis(Ref(-1.0))) == 1
        @test number_of_coordinates(M, DefaultOrthonormalBasis()) == 1
        rrcv = Manifolds.RieszRepresenterCotangentVector(M, 0.0, 1.0)
        @test flat(M, 0.0, 1.0) == rrcv
        @test sharp(M, 0.0, rrcv) == 1.0
        B_cot = Manifolds.dual_basis(M, 0.0, DefaultOrthonormalBasis())
        @test get_coordinates(M, 0.0, rrcv, B_cot) ≈ @SVector [1.0]
        @test get_vector(M, 0.0, 1.0, B_cot) isa Manifolds.RieszRepresenterCotangentVector
        a = fill(NaN)
        get_coordinates!(M, a, 0.0, rrcv, B_cot)
        @test a[] ≈ 1.0
        rrcv2 = Manifolds.RieszRepresenterCotangentVector(M, fill(0.0), fill(-10.0))
        get_vector!(M, rrcv2, 0.0, 1.0, B_cot)
        @test isapprox(rrcv.X, rrcv2.X[])
        @test vector_transport_to(M, 0.0, 1.0, 1.0, ParallelTransport()) == 1.0
        @test retract(M, 0.0, 1.0) == exp(M, 0.0, 1.0)
        @test injectivity_radius(M) ≈ π
        @test injectivity_radius(M, Ref(-2.0)) ≈ π
        @test injectivity_radius(M, Ref(-2.0), ExponentialRetraction()) ≈ π
        @test injectivity_radius(M, ExponentialRetraction()) ≈ π
        @test mean(M, [-π / 2, 0.0, π]) ≈ -π / 2
        @test mean(M, [-π / 2, 0.0, π], [1.0, 1.0, 1.0]) == -π / 2
        z = project(M, 1.5 * π)
        z2 = fill(0.0)
        project!(M, z2, 1.5 * π)
        @test z2[1] == z
        @test project(M, z) == z
        @test project(M, 1.0, 2.0) == 2.0

        # isapprox for 1-element vectors
        @test isapprox(M, [1.0], [1.0])
        @test isapprox(M, [0.0], [1.0], [1.0])

        # ManifoldDiff
        @test ManifoldDiff.adjoint_Jacobi_field(
            M,
            0.0,
            1.0,
            0.5,
            2.0,
            ManifoldDiff.βdifferential_shortest_geodesic_startpoint,
        ) === 2.0
        @test ManifoldDiff.diagonalizing_projectors(M, 0.0, 2.0) ==
              ((0.0, ManifoldDiff.ProjectorOntoVector(M, 0.0, SA[1.0])),)
        @test ManifoldDiff.jacobi_field(
            M,
            0.0,
            1.0,
            0.5,
            2.0,
            ManifoldDiff.βdifferential_shortest_geodesic_startpoint,
        ) === 2.0

        # volume
        @test manifold_volume(M) ≈ 2 * π
        @test volume_density(M, 0.0, 2.0) == 1.0
    end
    TEST_STATIC_SIZED && @testset "Real Circle and static sized arrays" begin
        X = @MArray fill(0.0)
        p = @SArray fill(0.0)
        log!(M, X, p, @SArray fill(π / 4))
        @test norm(M, p, X) ≈ π / 4
        @test is_vector(M, p, X)
        @test is_vector(M, [], X)
        @test project(M, 1.0) == 1.0
        p = @MArray fill(0.0)
        project!(M, p, p)
        @test p == @MArray fill(0.0)
        p .+= 2 * π
        project!(M, p, p)
        @test p == @MArray fill(0.0)
        @test project(M, 0.0, 1.0) == 1.0
    end
    types = [Float64]
    TEST_FLOAT32 && push!(types, Float32)

    basis_types = (DefaultOrthonormalBasis(),)
    basis_types_real = (
        DefaultOrthonormalBasis(),
        DiagonalizingOrthonormalBasis(Ref(-1.0)),
        DiagonalizingOrthonormalBasis(Ref(1.0)),
    )
    for T in types
        @testset "Type $T" begin
            pts = convert.(Ref(T), [-π / 4, 0.0, π / 4])
            test_manifold(
                M,
                pts,
                test_vector_spaces=false,
                test_project_point=true,
                test_project_tangent=true,
                test_musical_isomorphisms=true,
                test_default_vector_transport=true,
                test_vee_hat=false,
                is_mutating=false,
                test_rand_point=true,
                test_rand_tvector=true,
                rand_tvector_atol_multiplier=2.0,
            )
            ptsS = map(p -> (@SArray fill(p)), pts)
            test_manifold(
                M,
                ptsS,
                test_project_point=true,
                test_project_tangent=true,
                test_musical_isomorphisms=true,
                test_default_vector_transport=true,
                vector_transport_methods=[
                    ParallelTransport(),
                    SchildsLadderTransport(),
                    PoleLadderTransport(),
                ],
                test_vee_hat=true,
                basis_types_vecs=basis_types_real,
                basis_types_to_from=basis_types_real,
                test_rand_point=true,
                test_rand_tvector=true,
                rand_tvector_atol_multiplier=2.0,
            )
        end
    end
    @testset "Mutating Rand for real Circle" begin
        p = fill(NaN)
        X = fill(NaN)
        rand!(M, p)
        @test is_point(M, p)
        rand!(M, X; vector_at=p)
        @test is_vector(M, p, X)

        rng = MersenneTwister()
        rand!(rng, M, p)
        @test is_point(M, p)
        rand!(rng, M, X; vector_at=p)
        @test is_vector(M, p, X)
    end
    @testset "Test sym_rem" begin
        p = 4.0 # not a point
        p = sym_rem(p) # modulo to a point
        @test is_point(M, p)
    end
    Mc = Circle(ℂ)
    @testset "Complex Circle Basics" begin
        @test repr(Mc) == "Circle(ℂ)"
        @test representation_size(Mc) == ()
        @test manifold_dimension(Mc) == 1
        @test is_flat(Mc)
        @test is_vector(Mc, 1im, 0.0)
        @test is_point(Mc, 1im)
        @test !is_point(Mc, 1 + 1im)
        @test_throws DomainError is_point(Mc, 1 + 1im; error=:error)
        @test !is_vector(Mc, 1 + 1im, 0.0)
        @test_throws DomainError is_vector(Mc, 1 + 1im, 0.0; error=:error)
        @test !is_vector(Mc, 1im, 2im)
        @test_throws DomainError is_vector(Mc, 1im, 2im; error=:error)
        rrcv = Manifolds.RieszRepresenterCotangentVector(Mc, 0.0 + 0.0im, 1.0im)
        @test flat(Mc, 0.0 + 0.0im, 1.0im) == rrcv
        @test sharp(Mc, 0.0 + 0.0im, rrcv) == 1.0im
        @test norm(Mc, 1.0, log(Mc, 1.0, -1.0)) ≈ π
        @test is_vector(Mc, 1.0, log(Mc, 1.0, -1.0))
        X = @MArray fill(0.0 + 0.0im)
        p = @SArray fill(1.0 + 0.0im)
        log!(Mc, X, p, @SArray fill(-1.0 + 0.0im))
        @test norm(Mc, (@SArray fill(1.0)), X) ≈ π
        @test is_vector(Mc, p, X)
        @test project(Mc, 1.0) == 1.0
        @test project(Mc, 1 / sqrt(2.0) + 1 / sqrt(2.0) * im) ≈
              1 / sqrt(2.0) + 1 / sqrt(2.0) * im
        p = @MArray fill(1.0 + 0.0im)
        project!(Mc, p, p)
        @test p == @MArray fill(1.0 + 0.0im)
        p .*= 2
        project!(Mc, p, p)
        @test p == @MArray fill(1.0 + 0.0im)

        @test get_vector(Mc, fill(1.0 + 0.0im), [1.0]) isa Array{ComplexF64,0}

        angles = map(pp -> exp(pp * im), [-π / 2, 0.0, π])
        @test mean(Mc, angles) ≈ exp(-π * im / 2)
        @test mean(Mc, angles, [1.0, 1.0, 1.0]) ≈ exp(-π * im / 2)
        @test_throws ErrorException mean(Mc, [-1.0 + 0im, 1.0 + 0im])
        @test_throws ErrorException mean(Mc, [-1.0 + 0im, 1.0 + 0im], [1.0, 1.0])

        # volume
        @test manifold_volume(Mc) ≈ 2 * π
        @test volume_density(Mc, 1.0 + 0.0im, 2im) == 1.0
    end
    types = [Complex{Float64}]
    TEST_FLOAT32 && push!(types, Complex{Float32})

    @testset "small and large distance tests" begin
        p = -0.42681766710748265 + 0.9043377018818392im
        q = -0.42681766710748226 + 0.9043377018818393im
        @test isapprox(distance(Mc, p, q), 4.041272810440265e-16)
        @test isapprox(distance(Mc, p, -q), 3.1415926535897927; atol=eps())
    end

    for T in types
        @testset "Type $T" begin
            a = 1 / sqrt(2.0)
            pts = convert.(Ref(T), [a - a * im, 1 + 0im, a + a * im])
            test_manifold(
                Mc,
                pts,
                test_vector_spaces=false,
                test_project_tangent=true,
                test_musical_isomorphisms=true,
                test_default_vector_transport=true,
                is_mutating=false,
                test_vee_hat=false,
                exp_log_atol_multiplier=2.0,
                is_tangent_atol_multiplier=2.0,
                rand_tvector_atol_multiplier=4.0,
                test_rand_point=true,
                test_rand_tvector=true,
            )
            ptsS = map(p -> (@SArray fill(p)), pts)
            test_manifold(
                Mc,
                ptsS,
                test_project_tangent=true,
                test_musical_isomorphisms=true,
                test_default_vector_transport=true,
                test_vee_hat=true,
                exp_log_atol_multiplier=2.0,
                is_tangent_atol_multiplier=2.0,
                rand_tvector_atol_multiplier=4.0,
                basis_types_vecs=basis_types,
                basis_types_to_from=basis_types,
                test_rand_point=true,
                test_rand_tvector=true,
            )
        end
    end
    @testset "Mixed array dimensions for exp and PT" begin
        # this is an issue on Julia 1.6 but not later releases
        M = Circle()
        p = fill(0.0)
        Manifolds.exp_fused!(M, p, p, [1.0], 2.0)
        @test p ≈ fill(2.0)
        parallel_transport_to!(M, p, p, [4.0], p)
        @test p ≈ fill(4.0)
    end
end
