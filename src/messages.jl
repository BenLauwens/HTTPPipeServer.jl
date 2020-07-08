struct Request
    methodpath::String
    headers::Dict{String,String}
    params::Dict{Symbol,Any}
    files::Dict{String,Vector{UInt8}}
end

function Request(io::T) where T <: IO
    status = readline(io)
    method, target, version = split(status)
    headers = Dict{String,String}()
    while true
        header = readline(io)
        header === "" && break
        name, value = split(header, ": ")
        headers[name] = value
    end
    params = Dict{Symbol,Any}()
    files = Dict{String,Vector{UInt8}}()
    path, data = occursin("?", target) ? split(target, "?") : (target, nothing)
    methodpath = join((method, path), " ")
    data === nothing || for pair in split(data, "&")
        name, value = split(pair, "=")
        key = Symbol(name)
        params[key] = haskey(params, key) ? string(params[key], "; ", value) : value
    end
    if method in ("POST", "PUT", "DELETE")
        length = parse(Int64, get(headers, "Content-Length", "0"))
        data = String(read(io, length))
        contenttype = get(headers, "Content-Type", "")
        if contenttype == "application/x-www-form-urlencoded"
            for pair in split(data, "&")
                name, value = split(pair, "=")
                key = Symbol(name)
                params[key] = haskey(params, key) ? string(params[key], "; ", value) : value
            end
        elseif startswith(contenttype, "multipart/form-data;")
            boundary = split(contenttype, "=")[2]
            for part in split(data, boundary)
                startswith(part, "--") && continue
                field = split(part, "Content-Disposition: form-data; name=\"")[2]
                if occursin("filename", field)
                    name, value = split(field, "\"; filename=\"")
                    filename, content = split(value, "\"\r\nContent-Type:")
                    key = Symbol(name)
                    params[key] = haskey(params, key) ? string(params[key], "; ", filename) : filename
                    filename === "" && continue
                    content = split(split(content, "\r\n\r\n")[2], "\r\n--")[1]
                    files[filename] = Vector{UInt8}(content)
                else
                    name, value = split(field, "\"\r\n\r\n")
                    value = split(value, "\r\n--")[1]
                    key = Symbol(name)
                    params[key] = haskey(params, key) ? string(params[key], "; ", value) : value
                end
            end
        else
            @debug "POST without content type: $path"
        end
    end
    req = Request(
        methodpath, 
        headers,
        params,
        files
    )
end

function Base.getindex(req::Request, key::Symbol)
    req.params[key]
end

function Base.setindex!(req::Request, value::Any, key::Symbol)
    req.params[key] = value
end

function Base.get(req::Request, key::Symbol, value::Any)
    get(req.params, key, value)
end

struct Response
    version::String
    status::String
    headers::Vector{Pair{String,String}}
    body::Vector{UInt8}
    function Response(body::Vector{UInt8}=UInt8[]; status::String = "200 OK")
        new("HTTP/1.1", status, ["Content-Type" => "text/html; charset=utf-8", "X-Frame-Options" => "DENY"], body)
    end
end

function Response(body::String; status::String = "200 OK")
    Response(Vector{UInt8}(body); status=status)
end

function Base.write(io::IO, res::Response)
    push!(res.headers, "Content-Length" => string(sizeof(res.body)))
    write(io, res.version, " ", res.status, "\r\n")
    for header in res.headers
        write(io, header.first, ": ", header.second, "\r\n")
    end
    write(io, "\r\n")
    write(io, res.body)
end