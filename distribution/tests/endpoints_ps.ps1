Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'"

./standalone.ps1 --background

function checkStatus {
    if ($args[0] -notmatch $args[1]) {
        Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'" | foreach { kill $_.ProcessId }
        $test=$args[0]
        $check=$args[1]
        throw "Accessing $test does not output $check "
    }
}

$COUNTER = 0
$COUNTER_MAX = 60
$SLEEP_SECONDS = 1
$SERVICEUP = 0
Do {
    $result = (curl -v http://localhost:8080/auth/).StatusCode
    if ($result -eq "200") {
        $SERVICEUP = 1
    } else {
        start-sleep -s $SLEEP_SECONDS
        $COUNTER++
    }
   
} While ($SERVICEUP -eq 0 -and $COUNTER -lt $COUNTER_MAX) 

if ($SERVICEUP -ne 1) {
    throw "Identity Service timed out "
}

checkStatus (curl -v http://localhost:8080/auth/).StatusCode "200"
checkStatus (curl -v http://localhost:8080/auth/admin/alfresco/console/).StatusCode "200"
checkStatus (curl -v "http://localhost:8080/auth/realms/alfresco/protocol/openid-connect/auth?client_id=security-admin-console&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fauth%2Fadmin%2Falfresco%2Fconsole%2F&state=cd79cde9-02d2-4b9d-8299-870e638b7b6e&response_mode=fragment&response_type=code&scope=openid&nonce=fba6bbdb-27d4-49c1-8e7f-04fb4904fa5c").Content "Identity"
$Body = @{
   client_id = "alfresco"
   username = "admin"
   password = "admin"
   grant_type = "password"
}
checkStatus (Invoke-RestMethod "http://localhost:8080/auth/realms/alfresco/protocol/openid-connect/token" -Method Post -Body $Body).access_token "."

Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'"
Get-WmiObject Win32_Process -filter "CommandLine LIKE '%alfresco-identity-service-$IDENTITY_VERSION%'" | foreach { kill $_.ProcessId }