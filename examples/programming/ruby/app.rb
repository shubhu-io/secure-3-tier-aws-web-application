require 'puma'

items = []
server = Puma::Server.new(app: ->(env) {
  req = Rack::Request.new(env)
  method = req.request_method
  path = req.path_info

  case [method, path]
  when ["GET", "/"]
    [
      200,
      {"Content-Type" => "application/json"},
      [{"message" => "Welcome to the Ruby HTTP server"}.to_json]
    ]

  when ["GET", "/health"]
    [
      200,
      {"Content-Type" => "application/json"},
      [{"status" => "healthy"}.to_json]
    ]

  when ["GET", "/items"]
    [
      200,
      {"Content-Type" => "application/json"},
      [{"items" => items}.to_json]
    ]

  when ["POST", "/items"]
    body = req.body.read
    begin
      data = JSON.parse(body)
    rescue
      [400, {"Content-Type" => "application/json"}, [{"error" => "Invalid JSON"}.to_json]]
    else
      if data["name"].nil? || data["name"].empty?
        [400, {"Content-Type" => "application/json"}, [{"error" => "name is required"}.to_json]]
      else
        id = "item-#{items.length + 1}"
        items << {id: id, name: data["name"]}
        [201, {"Content-Type" => "application/json"}, [{"id" => id, "name" => data["name"]}.to_json]]
      end
    end

  when ["DELETE", "/items"]
    items.clear
    [200, {"Content-Type" => "application/json"}, [{"removed" => true}.to_json]]

  else
    [404, {"Content-Type" => "application/json"}, [{"error" => "Not found"}.to_json]]
  end
})

server.bind "tcp://0.0.0.0:3000"
server.run

loop do
  sleep 1
end