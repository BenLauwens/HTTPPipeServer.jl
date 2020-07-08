using Logging
using HTTPPipeServer
using NativeHTML

const LOGGER = Logging.SimpleLogger(stderr, Logging.Debug)
Logging.global_logger(LOGGER)

route("GET /") do req
    @debug "HANDLE GET /"
    io = IOBuffer()
    println(io, "<!DOCTYPE html>")
    println(io, "<html>")
    println(io, "  <h1>Test</h1>")
    println(io, "</html>")
    take!(io)
end

route("GET /helloworld") do req
    """
    <!DOCTYPE html>
    <html>
        <h1>Hello, World!</h1>
    </html>
    """
end

function HTTPPipeServer.Response(html::NativeHTML.HTML; status="200 OK")
    HTTPPipeServer.Response(html.data; status=status)
end

route("GET /nativeHTML") do req
    @debug "HANDLE GET /nativeHTML"
    html() do
        h1("NativeHTML")
        form(method="post", action="/test", enctype="multipart/form-data") do 
            input(class="input", type="email", name="email", id="email", placeholder="Email", autocomplete="email", autofocus=nothing)
            button("Go", type="submit")
        end
    end
end

route("POST /test") do req
    @debug "HANDLE POST /test"
    html() do
        p(req[:email])
    end
end

server = run("/tmp/test.sock")
readline()
close(server)
#wait(Condition())