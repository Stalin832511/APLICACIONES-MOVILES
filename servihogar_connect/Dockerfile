# 1. Etapa de compilación usando el SDK oficial de .NET 8 en el registro de Microsoft
FROM ://microsoft.com AS build
WORKDIR /src

# Copia el archivo de proyecto especificando la carpeta correcta
COPY ["ServiHogarConnect.API/ServiHogarConnect.API.csproj", "ServiHogarConnect.API/"]
RUN dotnet restore "ServiHogarConnect.API/ServiHogarConnect.API.csproj"

# Copia todo el código del repositorio
COPY . .

# Nos movemos a la carpeta de la API y compilamos
WORKDIR "/src/ServiHogarConnect.API"
RUN dotnet publish "ServiHogarConnect.API.csproj" -c Release -o /app/out

# 2. Etapa de ejecución usando el entorno ligero oficial de Microsoft
FROM ://microsoft.com AS runtime
WORKDIR /app
COPY --from=build /app/out .

# Configuración de puertos requerida por Render
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Comando para arrancar la API con el nombre de tu DLL
ENTRYPOINT ["dotnet", "ServiHogarConnect.API.dll"]
