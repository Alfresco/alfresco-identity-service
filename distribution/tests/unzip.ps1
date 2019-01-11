ls

Add-Type -AssemblyName System.IO.Compression.FileSystem
function unzip {
    param( [string]$ziparchive, [string]$extractpath )
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $ziparchive, $extractpath )
}

echo ${bamboo.prop.IDENTITY_VERSION}
echo ${bamboo.build.working.directory}

Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-${bamboo.prop.IDENTITY_VERSION}%'"
Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-${bamboo.prop.IDENTITY_VERSION}%'" | select-object -Property ProcessId
Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-${bamboo.prop.IDENTITY_VERSION}%'" | foreach { kill $_.ProcessId }

unzip "${bamboo.build.working.directory}\alfresco-identity-service-${bamboo.prop.IDENTITY_VERSION}.zip" '${bamboo.build.working.directory}'

ls