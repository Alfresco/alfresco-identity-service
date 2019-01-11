ls

Add-Type -AssemblyName System.IO.Compression.FileSystem
function unzip {
    $ziparchive=$args[0]
    $extractpath=$args[1]
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $ziparchive, $extractpath )
}

Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'"
Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'" | select-object -Property ProcessId
Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'" | foreach { kill $_.ProcessId }

unzip $WORKING_DIR\alfresco-identity-service-$IDENTITY_VERSION.zip $WORKING_DIR

ls