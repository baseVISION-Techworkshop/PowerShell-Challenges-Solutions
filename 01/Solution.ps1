##################################
# CHALLENGE 1 - POSSIBLE SOLUTIONS
##################################

# STANDARD

#region import azuread account from json files
$aadAccounts = Get-Content ".\data\AADAccounts.json" | ConvertFrom-Json
#endregion

#region count user objects
$aadAccounts.count
#endregion

#region count disabled user objects
(Measure-Command {
    ($aadAccounts | Where-Object { $_.accountEnabled -eq $false }).Count
}).TotalSeconds

(Measure-Command {
    $aadAccounts | Group-Object -Property accountEnabled
}).TotalSeconds
#endregion

#region count all users which have on of the following domain names assigned: alpineskihouse.com, basevision.ch, contoso.com
(Measure-Command -Expression {
    $domainNames = @('alpineskihouse.com', 'basevision.ch', 'contoso.com')
    $users = foreach ($account in $aadAccounts) {
        foreach ($domain in $domainNames) {
            if ($account.userPrincipalName.EndsWith($domain)) {
                $account.userPrincipalName
            }
        }
    }
}).TotalSeconds

(Measure-Command -Expression {
    $domainNames = @('alpineskihouse.com', 'basevision.ch', 'contoso.com')
    $users = $aadAccounts | Select-Object *, @{n = 'DomainName'; e = { ($_.userPrincipalName -split '@')[1] } } | Where-Object { $_.DomainName -in $domainNames }
}).TotalSeconds

(Measure-Command -Expression {
    $domainNames = @('alpineskihouse.com', 'basevision.ch', 'contoso.com')
    $users = $aadAccounts | Where-Object { ($_.userPrincipalName -split '@')[1] -in $domainNames }
}).TotalSeconds

(Measure-Command -Expression {
    $domainNames = @('alpineskihouse.com', 'basevision.ch', 'contoso.com').ForEach({ [regex]::Escape($_) }) -join '|'
    $users = $aadAccounts | Where-Object { $_.userPrincipalName -match $domainNames }
}).TotalSeconds


$users | Export-Csv -Path .\01\b2b-users.csv -Delimiter "," -NoTypeInformation
#endregion

# ADVANCED

#region count the number of users for each individual domain
# variant 1
$aadAccounts | Select-Object @{n = 'DomainName'; e = { ($_.userPrincipalName -split '@')[1] } } | Group-Object DomainName | Select-Object Count, Name

# variant 2
$domains = foreach ($account in $aadAccounts) {
    ($account.userPrincipalName -split '@')[1]
}
$domains | Group-Object | Select-Object Count, Name | Sort-Object Count -Descending
#endregion

#region list of users that have signed-in within the last 30 days
$referenceDate = (Get-Date).AddDays(-30)

# check it is a DateTime object type
$aadAccounts[0].additionalDetails.signInLogs.lastSignIn.GetType()

# get the list of users
$aadAccounts | Where-Object { $_.additionalDetails.signInLogs.lastSignIn -lt $referenceDate }
#endregion

#region add additional property
$today = Get-Date
foreach ($account in $aadAccounts) {
    $account.additionalDetails | Add-Member -MemberType NoteProperty -Name daysSinceLastSignIn -Value (New-TimeSpan -Start $account.additionalDetails.signInLogs.lastSignIn -End $today).Days
}
$aadAccounts | ConvertTo-Json -Depth 5 | Out-File .\01\signing-days-users.json
#endregion
