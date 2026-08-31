using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace example;

public class App
{
    private static readonly List<Dictionary<string, string>> items = new();

    public static async Task Main(string[] args)
    {
        int port = 8080;
        if (args.Length > 0)
        {
            if (int.TryParse(args[0], out int parsedPort))
            {
                port = parsedPort;
            }
        }

        var listener = new HttpListener();
        listener.Prefixes.Add($"http://+:{port}/");
        listener.Start();

        Console.WriteLine($"C# HTTP server running on port {port}");

        while (true)
        {
            var context = await listener.GetContextAsync();
            var request = context.Request;
            var response = context.Response;

            try
            {
                if (request.HttpMethod == "GET" && request.Url!.LocalPath == "/")
                {
                    response.StatusCode = 200;
                    response.ContentType = "application/json";
                    var json = "{\"message\":\"Welcome to the C# HTTP server\"}";
                    var buffer = Encoding.UTF8.GetBytes(json);
                    response.ContentLength64 = buffer.Length;
                    response.OutputStream.Write(buffer, 0, buffer.Length);
                    response.OutputStream.Close();
                }
                else if (request.HttpMethod == "GET" && request.Url!.LocalPath == "/health")
                {
                    response.StatusCode = 200;
                    response.ContentType = "application/json";
                    var json = "{\"status\":\"healthy\"}";
                    var buffer = Encoding.UTF8.GetBytes(json);
                    response.ContentLength64 = buffer.Length;
                    response.OutputStream.Write(buffer, 0, buffer.Length);
                    response.OutputStream.Close();
                }
                else if (request.HttpMethod == "GET" && request.Url!.LocalPath == "/items")
                {
                    response.StatusCode = 200;
                    response.ContentType = "application/json";
                    string json;
                    lock (items)
                    {
                        if (items.Count == 0)
                        {
                            json = "{\"items\":[]}";
                        }
                        else
                        {
                            var arr = new System.Text.StringBuilder("[");
                            bool first = true;
                            foreach (var item in items)
                            {
                                if (!first) arr.Append(',');
                                arr.Append("{\"id\":\"");
                                arr.Append(item["id"]!);
                                arr.Append("\",\"name\":\"");
                                arr.Append(item["name"]!);
                                arr.Append("\"}");
                                first = false;
                            }
                            arr.Append("]");
                            json = arr.ToString();
                        }
                    }
                    var buffer = Encoding.UTF8.GetBytes(json);
                    response.ContentLength64 = buffer.Length;
                    response.OutputStream.Write(buffer, 0, buffer.Length);
                    response.OutputStream.Close();
                }
                else if (request.HttpMethod == "POST" && request.Url!.LocalPath == "/items")
                {
                    response.StatusCode = 200;
                    response.ContentType = "application/json";

                    using var reader = new System.IO.StreamReader(request.InputStream, request.ContentEncoding);
                    var body = reader.ReadToEnd();

                    string name;
                    try
                    {
                        var dict = System.Text.Json.JsonSerializer.Deserialize<System.Collections.Generic.Dictionary<string, string>>(body);
                        name = dict?.ContainsKey("name") == true ? dict["name"] : null;
                    }
                    catch
                    {
                        name = null;
                    }

                    if (string.IsNullOrEmpty(name))
                    {
                        response.StatusCode = 400;
                        var errorJson = "{\"error\":\"name is required\"}";
                        var errorBuffer = Encoding.UTF8.GetBytes(errorJson);
                        response.ContentLength64 = errorBuffer.Length;
                        response.OutputStream.Write(errorBuffer, 0, errorBuffer.Length);
                        response.OutputStream.Close();
                        continue;
                    }

                    lock (items)
                    {
                        items.Add(new Dictionary<string, string>
                        {
                            ["id"] = Guid.NewGuid().ToString(),
                            ["name"] = name
                        });
                    }

                    response.StatusCode = 201;
                    var lastId = items[items.Count - 1]["id"];
                    var createdJson = $"{{\"id\":\"{lastId}\",\"name\":\"{name}\"}}";
                    var buffer = Encoding.UTF8.GetBytes(createdJson);
                    response.ContentLength64 = buffer.Length;
                    response.OutputStream.Write(buffer, 0, buffer.Length);
                    response.OutputStream.Close();
                }
                else if (request.HttpMethod == "DELETE" && request.Url!.LocalPath == "/items")
                {
                    lock (items)
                    {
                        items.Clear();
                    }

                    response.StatusCode = 200;
                    response.ContentType = "application/json";
                    var json = "{\"removed\":true}";
                    var buffer = Encoding.UTF8.GetBytes(json);
                    response.ContentLength64 = buffer.Length;
                    response.OutputStream.Write(buffer, 0, buffer.Length);
                    response.OutputStream.Close();
                }
                else
                {
                    response.StatusCode = 404;
                    response.ContentType = "application/json";
                    var json = "{\"error\":\"Not found\"}";
                    var buffer = Encoding.UTF8.GetBytes(json);
                    response.ContentLength64 = buffer.Length;
                    response.OutputStream.Write(buffer, 0, buffer.Length);
                    response.OutputStream.Close();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                try
                {
                    response.StatusCode = 500;
                    response.ContentType = "application/json";
                    var json = "{\"error\":\"Internal server error\"}";
                    var buffer = Encoding.UTF8.GetBytes(json);
                    response.ContentLength64 = buffer.Length;
                    response.OutputStream.Write(buffer, 0, buffer.Length);
                    response.OutputStream.Close();
                }
                catch { }
            }
        }
    }
}