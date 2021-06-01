# docker-multistage-build-publish-dotnet-core
Basic example to build an publish dotnet core core apps and packages to npm repo

## Docker prepare build stages

### Base image for final step

```Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
```
### Base image for build and publish steps

```Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
RUN apt-get install -y tar zip 
```
## How the build functions

### Create build.sh file to control the build.

```bash
set -eux
set echo off
# tarball csproj files, sln files, and other project files
find . \( -name "*.csproj" -o -name "*.sln" -o -name "NuGet.config" \) -print0 | tar -cvf projectfiles.tar --null -T -

#Trigger docker build and pass in the required build arguments for details like api keys for npm server
docker build --tag app:1.0.0 --build-arg api_key=mykey --build-arg version="1.0.0" .

#Remove the tarball once build is done
rm projectfiles.tar
```

### Restore only nuget packages.

This allows for the initial build stage to only restore nuget packages for the solution. and when rebuild is triggered this step will be executed from cache until we add new dependencies to the projects.

```Dockerfile
COPY projectfiles.tar .
# Extract the tarball to recreate the project structure without the source code.
RUN tar -xvf projectfiles.tar

# Runt the actual restore.
RUN dotnet restore
```

### Build the solution

```Dockerfile
COPY . .
RUN dotnet build --no-restore
```

### Publish the solution

```Dockerfile
FROM build AS publish

ARG api_key
ARG version

RUN dotnet publish --no-restore "./Presentation/MyApp.csproj" -o /app/publish

# publish and upload application to nexus server

RUN zip -r myApp.zip /app/publish   
RUN curl -v -u user:password --upload-file myApp.zip http://nexusserver/repository/develop/myApp.zip

# Package and publish libraries to nexus server
RUN dotnet pack -c Release -o /app/packages --no-restore --version-suffix $version
RUN dotnet nuget push "/app/packages/*.nupkg" --skip-duplicate --source http://nexusserver/repository/nuget/ --api-key $api_key

```

### Prepare for container registry

```Dockerfile
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApp.dll"]
```