#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <mutex>
#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/beast/http.hpp>

namespace beast = boost::beast;
namespace http = beast::http;
namespace net = boost::asio;
using tcp = net::ip::tcp;

std::mutex items_mutex;
std::map<std::string, std::string> items; // id -> name

std::string make_json_response(const std::string& key, const std::string& value) {
    return "{\"" + key + "\":\"" + value + "\"}";
}

std::string make_items_response() {
    std::lock_guard<std::mutex> lock(items_mutex);
    std::string json = "[";
    bool first = true;
    for (const auto& [id, name] : items) {
        if (!first) json += ",";
        json += "{\"id\":\"" + id + "\",\"name\":\"" + name + "\"}";
        first = false;
    }
    json += "]";
    return json;
}

void handle_request(http::request<http::string_body>& req, http::response<http::string_body>& res) {
    std::string path = req.target().to_string();
    std::string method = req.method_string();

    if (method == "GET" && path == "/") {
        res.result(http::status::ok);
        res.set(http::field::content_type, "application/json");
        res.body() = make_json_response("message", "Welcome to the C++ HTTP server");
        res.prepare_payload();
        return;
    }

    if (method == "GET" && path == "/health") {
        res.result(http::status::ok);
        res.set(http::field::content_type, "application/json");
        res.body() = make_json_response("status", "healthy");
        res.prepare_payload();
        return;
    }

    if (method == "GET" && path == "/items") {
        res.result(http::status::ok);
        res.set(http::field::content_type, "application/json");
        res.body() = make_items_response();
        res.prepare_payload();
        return;
    }

    if (method == "POST" && path == "/items") {
        // Simple body parsing for {"name":"xxx"}
        std::string body = req.body();
        std::string name;
        size_t name_pos = body.find("\"name\"");
        if (name_pos != std::string::npos) {
            size_t colon = body.find(':', name_pos);
            if (colon != std::string::npos) {
                size_t start = body.find('"', colon + 1);
                if (start != std::string::npos) {
                    size_t end = body.find('"', start + 1);
                    if (end != std::string::npos) {
                        name = body.substr(start + 1, end - start - 1);
                    }
                }
            }
        }

        if (name.empty()) {
            res.result(http::status::bad_request);
            res.set(http::field::content_type, "application/json");
            res.body() = make_json_response("error", "name is required");
            res.prepare_payload();
            return;
        }

        std::lock_guard<std::mutex> lock(items_mutex);
        std::string id = "item-" + std::to_string(items.size() + 1);
        items[id] = name;

        res.result(http::status::created);
        res.set(http::field::content_type, "application/json");
        res.body() = make_json_response("id", id) + ",{\"" + "name" + "\":\"" + name + "\"}";
        res.prepare_payload();
        return;
    }

    if (method == "DELETE" && path == "/items") {
        std::lock_guard<std::mutex> lock(items_mutex);
        items.clear();
        res.result(http::status::ok);
        res.set(http::field::content_type, "application/json");
        res.body() = make_json_response("removed", "true");
        res.prepare_payload();
        return;
    }

    res.result(http::status::not_found);
    res.set(http::field::content_type, "application/json");
    res.body() = make_json_response("error", "Not found");
    res.prepare_payload();
}

int main(int argc, char* argv[]) {
    unsigned short port = 8080;

    net::io_context ioc;
    tcp::acceptor acceptor(ioc, {tcp::v4(), port});

    for (;;) {
        tcp::socket socket(ioc);
        acceptor.accept(socket);

        beast::flat_buffer buffer;
        http::request<http::string_body> req;
        http::read(socket, buffer, req);

        http::response<http::string_body> res{http::status::ok, req.version()};
        handle_request(req, res);

        http::write(socket, res);
    }

    return 0;
}