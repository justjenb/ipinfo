$ProgressPreference = 'SilentlyContinue'

# Verify IP Address is valid and not a private address
$pattern = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
$privateRangepattern = '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'
do {
  $IPAddress = Read-Host 'Please enter an IP address to validate'
  $ok = $IPAddress -match $pattern
    if ($ok -eq $false) {
        Write-Warning ("'{0}' is not an IP address." -f $IPAddress)
        Write-Host -fore Red 'Please try again!'
        }
    elseif ($ok -eq $true) {
        $ok = $IPAddress -notmatch $privateRangepattern
            if ($ok -eq $false) {
                Write-Warning ("'{0}' is not a public IP address." -f $IPAddress)
                Write-Host -fore Red 'Please enter a publicy routable IP address.'
            }
        }
    } until ( $ok )


# Get user IP address    
$userIP = (Invoke-WebRequest -URI "https://api.ipify.org/").Content

# Get # of hops between local client and specified IP address and latency of 10 pings
$IPCheck = (Test-NetConnection -ComputerName $IPAddress -ErrorAction SilentlyContinue).PingSucceeded 
if ($IPCheck -eq "True") {
    # Get average latency for 10 pings
    $pingValues = Test-Connection $IPAddress -Count 10 -ErrorAction SilentlyContinue
    $pingAverage = ($pingValues.Latency | Measure-Object -Average).Average
    # Get hops
    $hops = (Test-NetConnection -TraceRoute -ComputerName $IPAddress -ErrorAction SilentlyContinue).TraceRoute.Count
    # Write output
    Write-Host "The average response time between your location at $userIP and $IPAddress is $pingAverage(ms)."
    Start-Sleep 3
    Write-Host "You are $hops hops away from $IPAddress."
    Start-Sleep 3    
}
    else {
        $hops = "Not available"
        $pingAverage = "Not available"
        Write-Host -fore Red "$IPAddress is not responding to traceroute requests. Number of hops and average response time cannot be retrieved."
        Start-Sleep 3
    }

# Get Netblock owner information
$header =@{"Accept"="application/xml"}
$ipLookup = Invoke-RestMethod -Method Get -Uri "http://whois.arin.net/rest/ip/$IPAddress" -Headers $header
$registeredOrganization = $ipLookup.net.OrgRef.Name
if ($null -eq $registeredOrganization){
    $registeredOrganization = $ipLookup.net.customerRef.Name
}
Write-Host "The owner of the Netblock is $registeredOrganization."
Start-Sleep 3

# Get initial GeoIP information
$geoLookup = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPAddress"

# Get City, State, Zip
$geoLookupCity = $geoLookup.City
$geoLookupState = $geoLookup.regionName
$geoLookupZip = $geoLookup.Zip
Write-Host "$IPAddress is located in $geoLookupCity, $geoLookupState, $geoLookupZip."
Start-Sleep 3

# Get ISP
$geoLookupISP = $geoLookup.ISP
Write-Host "The ISP for $IPAddress is $geoLookupISP."
Start-Sleep 3

# Get AS number owner
$geoLookupAsNum,$geoLookupAsOwner = $geoLookup.as.Split(" ",2)
Write-Host "The owner of the AS number is $geoLookupAsOwner."
Start-Sleep 3

# Get Lat/Longitude values for Zip code
$geoLookupLatLong = Invoke-RestMethod "https://graphical.weather.gov/xml/sample_products/browser_interface/ndfdXMLclient.php?zipCodeList=$geoLookupZip"
$geoLatLong = $geoLookupLatLong.dwml.data.location.point
$geoLat = $geoLatLong.latitude
$geoLon = $geoLatLong.longitude

# Get time using Lat/Lon values
$geoLookupTimeZone = Invoke-RestMethod -uri "http://api.timezonedb.com/v2.1/get-time-zone?key=8YS7YV5I8709&format=xml&by=position&lat=$geoLat&lng=$geoLon"
if ($geoLookupTimeZone.result.status -eq "OK") {
    $timeZone = $geoLookupTimeZone.result.zonename
    $geoLookupDateTimeQuery = Invoke-RestMethod -Uri "http://worldtimeapi.org/api/timezone/$timeZone"
    $geoLookupDate,$geoLookupTime = $geoLookupDateTimeQuery.datetime -Split ("T",2)
    $geoLookupTimeSplit1,$geoLookupTimeSplit2 = $geoLookupDate.Split(" ",2)
    Write-Host "The date and time in $geoLookupCity, $geoLookupState is currently $geoLookupTimeSplit1 at $geoLookupTimeSplit2."
    Start-Sleep 3
}
else {
    $geoLookupDate = "Not available"
    $geoLookupTimeSplit1 = "Not available"
    Write-Host -fore Red "Geo-location data for $IPAddress could not be retrieved at this time. The request failed. Unable to retrieve current time zone. IP Addresses located outside of the USA may not be available to query."
}

# Get weather information
$forecast = Invoke-RestMethod -Uri "http://wttr.in/{$geoLookupZip}?format=2"
Write-Host "The current weather forecast for $geoLookupCity, $geoLookupState, $geoLookupZip is below:"
$forecast
Start-Sleep 3

# JSON object export conversion
$allIPInformation = [PSCustomObject]@{
    IPAddress = "$IPAddress"
    NetworkTest = @(
        @{
            Result = "$hops"
            Query = "Number of hops from $userIP to $IPAddress."
        },
        @{
            Result = "$pingAverage"
            Query = "Average latency of 10 pings to $IPAddress in (ms)."
        }
    )
    IP_Info = @(
        @{
            Query = 'Netblock owner, As number owner, and ISP information.'
            Result = @{
                Netblock_Owner = "$registeredOrganization"
                AS_Number_Owner = "$geoLookupAsOwner"
                ISP = "$geoLookupISP"
            }
        }   
    )
    Geo_Location = @(
        @{
            Result = @{
                City = "$geoLookupCity"
                State = "$geoLookupState"
                Zip = "$geoLookupZip"
            }
        }
    )
    Date_Time_Weather = @(
        @{
            Query = "Current date and time."
            Result = @{
                Time = "$geoLookupTimeSplit2"
                Date = "$geoLookupTimeSplit1"
            }
        },
        @{
            Result = "$forecast"
            Query = "Weather forecast."
        }
    )
}
 
$jsonConvertedData = ConvertTo-Json -InputObject $allIPInformation -Depth 3
Start-Sleep 3

$showJson = Read-Host "Would you like to see a table of the data converted to JSON? y/n"
if ($showJson -eq 'y'){
    $jsonConvertedData
    Read-Host -Prompt "Press enter to continue and close this window"
}
else {
    Read-Host -Prompt "Press enter to continue and close this window"
}