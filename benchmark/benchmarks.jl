using BenchmarkTools
using Random
using LinearAlgebra

Random.seed!(0)

const SUITE = BenchmarkGroup()

# Matrix multiplication
SUITE["matmul"] = BenchmarkGroup()
suite = SUITE["matmul"]
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args = ["tiny"   => rand(T,2,2),
            "small"  => rand(T,10,10),
            "medium" => rand(T,10^2,10^2),
            "large"  => rand(T, 10^3,10^3)]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable $m * $m
    end
end

# Matrix batch-multiplication
SUITE["batchmul"] = BenchmarkGroup()
suite = SUITE["batchmul"]
function foo(m)
    cat( m[:,:,i] * m[:,:,i] for i in axes(m,3), dims=3)
end

for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args = ["tiny"   => rand(T,2,2,3),
            "small"  => rand(T,10,10,3),
            "medium" => rand(T,10^2,10^2,3),
            "large"  => rand(T, 10^3,10^3,3)]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable foo($m)
    end
end

#inner - reduction to scalar
SUITE["dot"] = BenchmarkGroup()
suite = SUITE["dot"]
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args = ["tiny"   => rand(T,fill(2,3)...)
            "small"  => rand(T,fill(10,3)...)
            "medium" => rand(T,fill(20,3)...)
            "large"  => rand(T,fill(50,3)...)
            "huge"   => rand(T,fill(10^2,3)...)]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable dot($m, $m)
    end
end

#trace
SUITE["trace"] = BenchmarkGroup()
suite = SUITE["trace"]
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args = ["tiny"   => rand(T,fill(2,2)...)
            "small"  => rand(T,fill(10,2)...)
            "medium" => rand(T,fill(10^2,2)...)
            "large"  => rand(T,fill(10^3,2)...)]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable tr($m)
    end
end

#partial trace
SUITE["ptrace"] = BenchmarkGroup()
suite = SUITE["ptrace"]
function foo(x)
    sum(x[i,i,:] for i in axes(x,1))
end
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args = ["tiny"   => rand(T,fill(2,3)...)
            "small"  => rand(T,fill(10,3)...)
            "medium" => rand(T,fill(20,3)...)
            "large"  => rand(T,fill(50,3)...)
            "huge"   => rand(T,fill(10^2,3)...)]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable foo($m)
    end
end

#diagonal
SUITE["diag"] = BenchmarkGroup()
suite = SUITE["diag"]
function foo(m)
    permutedims(reduce((x,y) -> cat(x,y, dims=3), m[:,i,i,:] for i in axes(m,2)), (1,3,2))
end
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(2,3)...)
            "small"  => rand(T,fill(10,3)...)
            "medium" => rand(T,fill(20,3)...)
            "large" => rand(T,fill(30,3)...)
            ]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable foo($m)
    end
end

#permutation
SUITE["perm"] = BenchmarkGroup()
suite = SUITE["perm"]
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(1,4)...)
            "small"  => rand(T,fill(2,4)...)
            "medium" => rand(T,fill(10,4)...)
            "large"  => rand(T,fill(30,4)...)
            ]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable permutedims($m, (4,2,3,1))
    end
end

#permutation
SUITE["tcontract"] = BenchmarkGroup()
suite = SUITE["tcontract"]
function foo(x,y)
    xy = zeros(eltype(x),size(x,1), size(y,2))
    for (i,j,k,l) in Iterators.product(axes(x,1), axes(y,2), axes(x,2), axes(y,3))
        xy[i,j] += x[i,k,l] * y[k,j,l]
    end
    return xy
end
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(1,3)...)
            "small"  => rand(T,fill(2,3)...)
            "medium" => rand(T,fill(10,3)...)
            "large"  => rand(T,fill(30,3)...)
            ]

    for (k,m) in args
        suite[string(T)][k] = @benchmarkable foo($m,$m)
    end
end

#permutation
SUITE["star"] = BenchmarkGroup()
suite = SUITE["star"]
function foo(x,y,z)
    xyz = zeros(eltype(x),size(x,2), size(y,2), size(z,2))
    for (i,j,k,l) in Iterators.product(axes(x,1), axes(x,2), axes(y,2), axes(z,2))
        xyz[j,k,l] += x[i,j] * y[i,k] * z[i,l]
    end
    return xy
end
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(2,2)...)
            "small"  => rand(T,fill(10,2)...)
            "medium" => rand(T,fill(30,2)...)
            "large"  => rand(T,fill(100,2)...)
            ]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable foo($m,$m)
    end
end

#star and contract
SUITE["star&contract"] = BenchmarkGroup()
suite = SUITE["star&contract"]
function foo(x,y,z)
    xyz = zeros(size(x,2))
    for (i,j,k,l) in Iterators.product(axes(x,1), axes(x,2), axes(y,2), axes(z,2))
        xyz[j] += x[i,j] * y[i,l] * z[i,l]
    end
    return xy
end
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(2,2)...)
            "small"  => rand(T,fill(10,2)...)
            "medium" => rand(T,fill(30,2)...)
            "large"  => rand(T,fill(100,2)...)
            ]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable foo($m,$m)
    end
end

# index-sum
SUITE["indexsum"] = BenchmarkGroup()
suite = SUITE["indexsum"]
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(2,3)...)
            "small"  => rand(T,fill(10,3)...)
            "medium" => rand(T,fill(30,3)...)
            "large"  => rand(T,fill(100,3)...)
            ]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable sum($m, dims=2)
    end
end

# Hadamard
SUITE["hadamard"] = BenchmarkGroup()
suite = SUITE["hadamard"]
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(2,3)...)
            "small"  => rand(T,fill(10,3)...)
            "medium" => rand(T,fill(30,3)...)
            "large"  => rand(T,fill(100,3)...)
            ]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable $m .* $m
    end
end

# Outer
SUITE["outer"] = BenchmarkGroup()
suite = SUITE["outer"]
function foo(x,y)
    xp = reshape(x, size(x)...,1,1)
    yp = reshape(y, 1,1,size(y)...)
    xp .* yp
end
for T in (Float32, Float64, ComplexF32, ComplexF64)
    suite[string(T)] = BenchmarkGroup()
    args =  [
            "tiny"   => rand(T,fill(2,2)...)
            "small"  => rand(T,fill(10,2)...)
            "medium" => rand(T,fill(50,2)...)
            "large"  => rand(T,fill(100,2)...)
            ]
    for (k,m) in args
        suite[string(T)][k] = @benchmarkable foo($m, $m)
    end
end
