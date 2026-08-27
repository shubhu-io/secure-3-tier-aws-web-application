FROM mcr.microsoft.com/dotnet/runtime:9.0-alpine AS runtime

WORKDIR /app

COPY bin/Release/net9.0/*/publish .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://127.0.0.1:8080/health || exit 1

CMD ["./DotNetHttpServer"]