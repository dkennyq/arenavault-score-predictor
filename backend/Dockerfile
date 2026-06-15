FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ArenaVault.API/ArenaVault.API.csproj ArenaVault.API/
RUN dotnet restore ArenaVault.API/ArenaVault.API.csproj

COPY . .
WORKDIR /src/ArenaVault.API
RUN dotnet build ArenaVault.API.csproj -c Release -o /app/build

FROM build AS publish
RUN dotnet publish ArenaVault.API.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
EXPOSE 5000
ENTRYPOINT ["dotnet", "ArenaVault.API.dll"]
