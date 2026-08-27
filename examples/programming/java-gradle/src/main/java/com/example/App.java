package com.example;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class App {
    private static final List<Map<String, String>> items = new ArrayList<>();

    public static void main(String[] args) throws IOException {
        int port = 8080;
        if (args.length > 0) {
            try { port = Integer.parseInt(args[0]); } catch (NumberFormatException ignored) {}
        }

        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/", exchange -> {
            String response = """
                {"message":"Welcome to the Java HTTP server"}
                """;
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.getBytes().length);
            exchange.getResponseBody().write(response.getBytes());
            exchange.getResponseBody().close();
        });

        server.createContext("/health", exchange -> {
            String response = """
                {"status":"healthy"}
                """;
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.getBytes().length);
            exchange.getResponseBody().write(response.getBytes());
            exchange.getResponseBody().close();
        });

        server.createContext("/items", exchange -> {
            if ("POST".equals(exchange.getRequestMethod())) {
                String body = new String(exchange.getRequestBody().readAllBytes());
                String name = extractName(body);
                if (name == null) {
                    String error = "{\"error\":\"name is required\"}";
                    exchange.getResponseHeaders().set("Content-Type", "application/json");
                    exchange.sendResponseHeaders(400, error.getBytes().length);
                    exchange.getResponseBody().write(error.getBytes());
                    exchange.getResponseBody().close();
                    return;
                }
                java.util.Map<String, String> item = java.util.Map.of("id", String.valueOf(System.currentTimeMillis()), "name", name);
                items.add(item);
                String resp = String.format("{\"id\":\"%s\",\"name\":\"%s\"}", item.get("id"), name);
                exchange.getResponseHeaders().set("Content-Type", "application/json");
                exchange.sendResponseHeaders(201, resp.getBytes().length);
                exchange.getResponseBody().write(resp.getBytes());
                exchange.getResponseBody().close();
            } else if ("DELETE".equals(exchange.getRequestMethod())) {
                items.clear();
                String resp = "{\"removed\":true}";
                exchange.getResponseHeaders().set("Content-Type", "application/json");
                exchange.sendResponseHeaders(200, resp.getBytes().length);
                exchange.getResponseBody().write(resp.getBytes());
                exchange.getResponseBody().close();
            } else {
                String error = "{\"error\":\"Not found\"}";
                exchange.getResponseHeaders().set("Content-Type", "application/json");
                exchange.sendResponseHeaders(404, error.getBytes().length);
                exchange.getResponseBody().write(error.getBytes());
                exchange.getResponseBody().close();
            }
        });

        server.setExecutor(null);
        server.start();
        System.out.println("Java HTTP server running on port " + port);
    }

    private static String extractName(String body) {
        if (body == null || body.isEmpty()) return null;
        int nameIdx = body.indexOf("\"name\"");
        if (nameIdx < 0) return null;
        int colonIdx = body.indexOf(':', nameIdx);
        if (colonIdx < 0) return null;
        int start = colonIdx + 1;
        while (start < body.length() && (body.charAt(start) == ' ' || body.charAt(start) == '"')) start++;
        int end = body.indexOf('"', start);
        if (end < 0) return null;
        return body.substring(start, end);
    }
}