ls

Add-Type -AssemblyName System.IO.Compression.FileSystem

Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'"
Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'" | select-object -Property ProcessId
Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'" | foreach { kill $_.ProcessId }

$ziparchive = "$WORKING_DIR\alfresco-identity-service-$IDENTITY_VERSION.zip"
$extractpath = "$WORKING_DIR"
[System.IO.Compression.ZipFile]::ExtractToDirectory( $ziparchive, $extractpath )