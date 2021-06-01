FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
RUN apt-get install -y tar zip 

COPY projectfiles.tar .
RUN tar -xvf projectfiles.tar
RUN dotnet restore

COPY . .
RUN dotnet build --no-restore

FROM build AS publish
ARG api_key
ARG version
RUN dotnet publish --no-restore "./Presentation/MyApp.csproj" -o /app/publish
RUN zip -r myApp.zip /app/publish   
RUN curl -v -u user:password --upload-file myApp.zip http://nexus-server/repository/develop/apps/myApp.zip
RUN dotnet pack -c Release -o /app/packages --no-restore --version-suffix $version
RUN dotnet nuget push "/app/packages/*.nupkg" --skip-duplicate --source http://nexus-server/repository/nuget/ --api-key $api_key

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApp.dll"]