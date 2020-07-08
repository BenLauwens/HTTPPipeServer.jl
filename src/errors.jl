function error400()
    Response(ROUTES["GET /error400"](); status="400 Bad Request")
end

function error404(req::Request)
    Response(ROUTES["GET /error404"](req); status="404 Not Found")
end

function error500(req::Request)
    Response(ROUTES["GET /error500"](req); status="500 Internal Server Error")
end

function htmlerror(io::IOBuffer)
    for (exc, bt) in Base.catch_stack()
        print(io, "  <p>")
        showerror(io, exc)
        println(io, "</p>")
        println(io, "  <p>")
        iotr = IOBuffer()
        Base.show_backtrace(iotr, bt)
        println(io, replace(String(take!(iotr))[2:end], "\n" => "\n<br>"))
        println(io, "</p>")
    end
end

function __init__()
    route("GET /error400") do 
        io = IOBuffer()
        println(io, "<!DOCTYPE html>")
        println(io, "<html>")
        println(io, "  <h1>400 Bad Request</h1>")
        htmlerror(io)
        println(io, "</html>")
        take!(io)
    end

    route("GET /error404") do req
        """<!DOCTYPE html>
        <html>
          <h1>404 Not Found</h1>
          <p>$(req.methodpath)</p>
        </html>"""
    end

    route("GET /error500") do req
        io = IOBuffer()
        println(io, "<!DOCTYPE html>")
        println(io, "<html>")
        println(io, "  <h1>500 Internal Server Error</h1>")
        println(io, "  <p>Request: ", req.methodpath, "</p>")
        htmlerror(io)
        println(io, "</html>")
        take!(io)
    end
end