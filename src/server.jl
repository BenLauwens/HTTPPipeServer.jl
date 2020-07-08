using Sockets

function Base.run(socketpath::String; middleware::Function=routemiddleware)
    rm(socketpath, force = true)
    server = Sockets.listen(socketpath)
    chmod(socketpath, 0o777)
    @debug "SERVER STARTED: $socketpath"
    @async while isopen(server)
        io = accept(server)
        @debug "CONNECTION ACCEPTED"
        @async let io = io
            res = nothing
            try
                req = Request(io)
                try
                    @debug "REQUEST ACCEPTED: $(req.methodpath)"
                    res = middleware(req) 
                    @debug "REQUEST PROCESSED: $(req.methodpath)"
                catch
                    @debug "ERROR: INTERNAL SERVER ERROR"
                    for (exc, bt) in Base.catch_stack()
                        showerror(stderr, exc, bt)
                        @debug stderr
                    end
                    res = error500(req)
                end
            catch
                @debug "ERROR: BAD REQUEST"
                for (exc, bt) in Base.catch_stack()
                    showerror(stderr, exc, bt)
                    @debug stderr
                end
                res = error400()
            finally
                if isopen(io)
                    write(io, res)
                    @debug "RESPONSE SENT"
                end
                @debug "CONNECTION FINISHED"
            end
        end
    end
    server
end