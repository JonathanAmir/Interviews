# Define the time span
$DaysInactive = 180
$TimeSpan = (Get-Date).AddDays(-$DaysInactive)

# Search for inactive users
$InactiveUsers = Get-ADUser -Filter {LastLogonDate -lt $TimeSpan} -Properties LastLogonDate | Where-Object { $_.LastLogonDate -ne $null }

# Display the results
$InactiveUsers | Select-Object Name, LastLogonDate | Format-Table -AutoSize
