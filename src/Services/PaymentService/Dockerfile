# Use the official .NET 8 runtime as base image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Use the official .NET 8 SDK for building
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["src/Services/PaymentService/PaymentService.csproj", "src/Services/PaymentService/"]
COPY ["src/Shared/Shared.Domain/Shared.Domain.csproj", "src/Shared/Shared.Domain/"]

# Restore dependencies
RUN dotnet restore "src/Services/PaymentService/PaymentService.csproj"

# Copy all source code
COPY . .

# Build the application
WORKDIR "/src/src/Services/PaymentService"
RUN dotnet build "PaymentService.csproj" -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "PaymentService.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Create final runtime image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["dotnet", "PaymentService.dll"]

