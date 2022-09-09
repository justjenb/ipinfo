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
    Write-Warning ("'{0}' is not a public IP address." -f $ip)
    Write-Host -fore Red 'Please enter a publicy routable IP address.'
    $IPAddress = Read-Host 'Please enter an IP address to validate'
  }
} until ( $ok )

