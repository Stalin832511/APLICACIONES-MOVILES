FROM ://microsoft.com AS build
WORKDIR /src
COPY ["ServiHogarConnect.API/ServiHogarConnect.API.csproj", "ServiHogarConnect.API/"]
RUN dotnet restore "ServiHogarConnect.API/ServiHogarConnect.API.csproj"
COPY . .
WORKDIR "/src/ServiHogarConnect.API"
RUN dotnet publish "ServiHogarConnect.API.csproj" -c Release -o /app/out
FROM ://microsoft.com AS runtime
WORKDIR /app
COPY --from=build /app/out .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "ServiHogarConnect.API.dll"]
