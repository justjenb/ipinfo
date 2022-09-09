$allIPpattern = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

do {
  $IPAddress = Read-Host 'Please enter an IP address to validate'
  $ok = $IPAddress -match $allIPpattern
  if ($ok -eq $false) {
    Write-Warning ("'{0}' is not an IP address." -f $IPAddress)
    Write-Host -fore Red 'Please try again!'
  }
} until ( $ok )