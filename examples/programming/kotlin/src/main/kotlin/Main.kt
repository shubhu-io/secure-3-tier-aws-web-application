import com.google.gson.Gson
import com.google.gson.JsonObject
import com.squareup.okhttp.OkHttpClient
import com.squareup.okhttp.Request
import com.squareup.okhttp.Response
import java.util.*

class Item(val id: String, val name: String)

fun main() {
    val server = object : com.sun.net.httpserver.HttpHandler {
        val items = mutableListOf<Item>()
        val gson = Gson()

        override handle(exchange: com.sun.net.httpserver.HttpExchange) {
            val path = exchange.requestURI.path
            val method = exchange.requestMethod

            when {
                path == "/" && method == "GET" -> {
                    val response = mapOf("message" to "Welcome to the Kotlin HTTP server")
                    val json = gson.toJson(response)
                    exchange.sendResponseHeaders(200, json.length.toLong())
                    exchange.responseBody.write(json.toByteArray())
                    exchange.responseBody.close()
                }
                path == "/health" && method == "GET" -> {
                    val response = mapOf("status" to "healthy")
                    val json = gson.toJson(response)
                    exchange.sendResponseHeaders(200, json.length.toLong())
                    exchange.responseBody.write(json.toByteArray())
                    exchange.responseBody.close()
                }
                path == "/items" && method == "GET" -> {
                    val response = mapOf("items" to items)
                    val json = gson.toJson(response)
                    exchange.sendResponseHeaders(200, json.length.toLong())
                    exchange.responseBody.write(json.toByteArray())
                    exchange.responseBody.close()
                }
                path == "/items" && method == "POST" -> {
                    val inputStream = exchange.requestBody
                    val jsonString = inputStream.readBytes().toString(Charsets.UTF_8)
                    try {
                        val jsonObject = gson.fromJson(jsonString, JsonObject::class.java)
                        val name = jsonObject.get("name").getAsString()
                        val item = Item("item-${items.size + 1}", name)
                        items.add(item)
                        exchange.sendResponseHeaders(201, 0.toLong())
                        exchange.responseBody.close()
                    } catch (e: Exception) {
                        val errorResponse = mapOf("error" to "Invalid JSON or missing name")
                        val json = gson.toJson(errorResponse)
                        exchange.sendResponseHeaders(400, json.length.toLong())
                        exchange.responseBody.write(json.toByteArray())
                        exchange.responseBody.close()
                    }
                }
                path == "/items" && method == "DELETE" -> {
                    items.clear()
                    val response = mapOf("removed" to true)
                    val json = gson.toJson(response)
                    exchange.sendResponseHeaders(200, json.length.toLong())
                    exchange.responseBody.write(json.toByteArray())
                    exchange.responseBody.close()
                }
                else -> {
                    val errorResponse = mapOf("error" to "Not found")
                    val json = gson.toJson(errorResponse)
                    exchange.sendResponseHeaders(404, json.length.toLong())
                    exchange.responseBody.write(json.toByteArray())
                    exchange.responseBody.close()
                }
            }
        }
    }

    val port = System.getenv("PORT")?.toInt() ?: 8080
    val httpServer = com.sun.net.httpserver.HttpServer.create(java.net.InetSocketAddress(port), 0)
    httpServer.createContext("/", server)
    httpServer.setExecutor(null)
    httpServer.start()
    println("Kotlin HTTP server running at http://localhost:$port/")
}