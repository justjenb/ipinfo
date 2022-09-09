$allIPpattern = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

do {
  $IPAddress = Read-Host 'Please enter an IP address to validate'
  $ok = $IPAddress -match $allIPpattern
  if ($ok -eq $false) {
    Write-Warning ("'{0}' is not an IP address." -f $IPAddress)
    Write-Host -fore Red 'Please try again!'
  }
} until ( $ok )

$privateRangepattern = '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'

do {
  $ok = $IPAddress -notmatch $privateRangepattern
  if ($ok -eq $false) {
    Write-Warning ("'{0}' is not a public IP address." -f $IPAddress)
    Write-Host -fore Red 'Please enter a publicy routable IP address.'
    $IPAddress = Read-Host 'Please enter an IP address to validate'
  }
} until ( $ok )

$userIP = (Invoke-WebRequest -URI "https://api.ipify.org/").Content

$hops = (Test-NetConnection -TraceRoute -ComputerName "$IPAddress").TraceRoute.Count

Write-Host "You are $hops hops away from $IPAddress."

$pingValues = Test-Connection $IPAddress -Count 10
$pingAverage = ($pingValues.ResponseTime | Measure-Object -Average).Average

Write-Host "The average response time between your location at $userIP and $IPAddress is $pingAverage(ms)."

$header =@{"Accept"="application/xml"}
$ipLookup = Invoke-RestMethod -Method Get -Uri "http://whois.arin.net/rest/ip/$IPAddress" -Headers $header

$propHash=[ordered]@{
        IP = $IPAddress
        Name = $ipLookup.net.name
        RegisteredOrganization = $ipLookup.net.orgRef.name
        City = (Invoke-RestMethod $ipLookup.net.orgRef.'#text').org.city
        StartAddress = $ipLookup.net.startAddress
        EndAddress = $ipLookup.net.endAddress
        NetBlocks = $ipLookup.net.netBlocks.netBlock | foreach {"$($_.startaddress)/$($_.cidrLength)"}
        Updated = $ipLookup.net.updateDate -as [datetime]
        }
        [pscustomobject]
Write-Host "The owner of the netblock is $ipLookup.net.orgRef.name. Full Netblock information:"
$propHash


