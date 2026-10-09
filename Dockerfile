ARG REGISTRY=mcr
ARG DOMAIN=microsoft
ARG TLD=com

FROM ${REGISTRY}.${DOMAIN}.${TLD}/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
WORKDIR "/src/ServiHogarConnect.API"
RUN dotnet publish "ServiHogarConnect.API.csproj" -c Release -o /app/out

FROM ${REGISTRY}.${DOMAIN}.${TLD}/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/out .
ENV ASPNETCORE_URLS=http://+:${PORT:-10000}
ENTRYPOINT ["dotnet", "ServiHogarConnect.API.dll"]
