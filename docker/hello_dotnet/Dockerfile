FROM mcr.microsoft.com/dotnet/sdk:7.0 AS builder
WORKDIR /app
COPY . .
RUN dotnet restore
RUN dotnet publish  -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80 443
COPY --from=builder /app/publish .
ENV TZ Asia/Shanghai
ENTRYPOINT ["dotnet", "HelloDotnet.dll"]