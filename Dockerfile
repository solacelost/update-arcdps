FROM mcr.microsoft.com/powershell:lts-centos-8

ENV UPDATE_ARCDPS_VERSION="0.6.0" \
    APPDATA="/app/data" \
    PUBLISH_BUILD="" \
    NUGETAPIKEY=""

COPY Prepare-TestEnvironment.ps1 /app/Prepare-TestEnvironment.ps1
RUN pwsh /app/Prepare-TestEnvironment.ps1

COPY publish /app/publish
COPY Update-ArcDPS /app/Update-ArcDPS
COPY run-tests.sh /app/run-tests.sh
RUN /app/run-tests.sh

CMD pwsh -Command 'if ($env:PUBLISH_BUILD) { . /app/publish/Publish-FlattenedUpdateArcDPS.ps1 }'
