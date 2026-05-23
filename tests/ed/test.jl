#!/usr/bin/env julia

packages = ["StatsBase"]
failed = String[]

for pkg in packages
    try
        @eval using $pkg
    catch
        push!(failed, pkg)
    end
end

if !isempty(failed)
    @error "FAIL: $(join(failed, ", "))"
    exit(1)
end

println("PASS: all packages loaded")
