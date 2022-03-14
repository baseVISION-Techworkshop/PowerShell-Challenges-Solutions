##################################
# CHALLENGE 2 - POSSIBLE SOLUTIONS
##################################

# STANDARD

#region import data

## IMPORT CSV
$applicationList = Import-Csv ".\data\ApplicationList.csv"

## IMPORT JSON
$aadAccounts = Get-Content ".\data\AADAccounts.json" | ConvertFrom-Json

#endregion

#region get list of applications

## CREATE A LIST WITH THE INFORMATION FROM THE APPLICATION LIST FOR ALL USERS THAT ARE PRESENT IN THE AZUREAD USER LIST.

# using where object in foreach loop
(Measure-Command -Expression {
    #command
    foreach ($account in $aadAccounts) {
        $applicationList | Where-Object { $_.userPrincipalName -eq $account.userPrincipalName }
    }
}).TotalSeconds

#using the -in operator from challenge 1 :-)
(Measure-Command -Expression {
    #command
    $applicationList | Where-Object { $_.userPrincipalName -in $aadAccounts.userPrincipalName }
}).TotalSeconds

# create lookup table and get data
(Measure-Command -Expression {
    #command
    $lookup = $applicationList | Group-Object -Property userPrincipalName -AsHashTable -AsString
    foreach ($account in $aadAccounts) {
        $lookup[$account.userPrincipalName]
    }
}).TotalSeconds
#endregion

#region add data lookup table

## ADD THE RISKLEVEL OF THE USER TO THE LIST FROM THE AZURE AD ACCOUNT LIST.

(Measure-Command -Expression {
    $lookup = $applicationList | Group-Object -Property userPrincipalName -AsHashTable -AsString
    foreach ($account in $aadAccounts) {
        if ($lookup.ContainsKey($account.userPrincipalName)) {
            $lookup[$account.userPrincipalName] | Select-Object *, @{n = 'riskLevel'; e = { $account.additionalDetails.identityProtection.riskLevel } }
        }
    }
}).TotalSeconds

(Measure-Command -Expression {
    $lookup = $applicationList | Group-Object -Property userPrincipalName -AsHashTable -AsString
    foreach ($account in $aadAccounts) {
        if ($lookup.ContainsKey($account.userPrincipalName)) {
            [PSCustomObject]@{
                ip_address          = $lookup[$account.userPrincipalName].ip_address
                application         = $lookup[$account.userPrincipalName].application
                application_version = $lookup[$account.userPrincipalName].application_version
                userPrincipalName   = $lookup[$account.userPrincipalName].userPrincipalName
                riskLevel           = $account.additionalDetails.identityProtection.riskLevel
            }
        }
    }
}).TotalSeconds

#endregion

# ADVANCED

#region store data in multiple variables
(Measure-Command -Expression {
    $foundObjects = @()
    $enabledObjects = @()
    $lookup = $applicationList | Group-Object -Property userPrincipalName -AsHashTable -AsString

    foreach ($account in $aadAccounts) {
        if ($lookup.ContainsKey($account.userPrincipalName)) {
            $foundObjects += [PSCustomObject]@{
                displayName       = $account.displayName
                userPrincipalName = $account.userPrincipalName
                accountEnabled    = $account.accountEnabled
                applicationsFound = @($lookup[$account.userPrincipalName].Application).Count
                risklevel         = $account.additionalDetails.identityProtection.riskLevel
            }

        }
        elseif ($account.accountEnabled) {
            $enabledObjects += [PSCustomObject]@{
                displayName       = $account.displayName
                jobTitle          = $account.jobTitle
                userPrincipalName = $account.userPrincipalName
                accountEnabled    = $account.accountEnabled
                lastLogon         = $account.additionalDetails.signInLogs.lastSignIn
            }
        }
    }
}).TotalSeconds

(Measure-Command -Expression {
    $foundObjects = [System.Collections.Generic.List[PSObject]]::new()
    $enabledObjects = [System.Collections.Generic.List[PSObject]]::new()
    $lookup = $applicationList | Group-Object -Property userPrincipalName -AsHashTable -AsString

    foreach ($account in $aadAccounts) {
        if ($lookup.ContainsKey($account.userPrincipalName)) {
            $foundObjects.Add(
                [PSCustomObject]@{
                    displayName       = $account.displayName
                    userPrincipalName = $account.userPrincipalName
                    accountEnabled    = $account.accountEnabled
                    applicationsFound = @($lookup[$account.userPrincipalName].Application).Count
                    risklevel         = $account.additionalDetails.identityProtection.riskLevel
                }
            )
        }
        elseif ($account.accountEnabled) {
            $enabledObjects.Add(
                [PSCustomObject]@{
                    displayName       = $account.displayName
                    jobTitle          = $account.jobTitle
                    userPrincipalName = $account.userPrincipalName
                    accountEnabled    = $account.accountEnabled
                    lastLogon         = $account.additionalDetails.signInLogs.lastSignIn
                }
            )
        }
    }
}).TotalSeconds

#endregion