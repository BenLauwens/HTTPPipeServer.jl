const ROUTES = Dict{String, Function}()

function route(handle::Function, methodpath::String)
    @debug "ADD ROUTE: $methodpath"
    haskey(ROUTES, methodpath)
    ROUTES[methodpath] = handle
    nothing
end

function routemiddleware(req::Request)
    @debug "ROUTE $(req.methodpath)"
    req.methodpath in keys(ROUTES) || return error404(req)
    Response(ROUTES[req.methodpath](req); status="200 OK")
end