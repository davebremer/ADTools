function Get-ADReports {
<#
.SYNOPSIS
	This function retrieves all reportsfrom the Identity Specified.
	Optionally you can specify the DirectOnly parameter to find just the direct reports
	
.DESCRIPTION
	This function retrieves all reportsfrom the Identity Specified.
	Optionally you can specify the DirectOnly parameter to find just the direct reports

	
.PARAMETER Identity
	Specify the account to inspect
	
.PARAMETER Recurse
	Specify that you want to retrieve all the indirect users under the account
	
.EXAMPLE
	Get-ADReports -Identity Test_director
	
Name                SamAccountName      Mail                Manager
----                --------------      ----                -------
test_managerB       test_managerB       test_managerB@la... test_director
test_managerA       test_managerA       test_managerA@la... test_director
		
	.EXAMPLE
		Get-ADReports -Identity Test_director -Recurse
	
Name                SamAccountName      Mail                Manager
----                --------------      ----                -------
test_managerB       test_managerB       test_managerB@la... test_director
test_userB1         test_userB1         test_userB1@lazy... test_managerB
test_userB2         test_userB2         test_userB2@lazy... test_managerB
test_managerA       test_managerA       test_managerA@la... test_director
test_userA2         test_userA2         test_userA2@lazy... test_managerA
test_userA1         test_userA1         test_userA1@lazy... test_managerA

.NOTES
    Based on a script by Francois-Xavier Cat, www.lazywinadmin.com	@lazywinadm
    https://gallery.technet.microsoft.com/scriptcenter/Get-ADDirectReport-962616c6/view/Discussions
	
    Rewritten 2020/5/29
#>
#Requires -Modules ActiveDirectory

[CmdletBinding()]
PARAM (
	[Parameter(Mandatory)]
	[String[]]$Identity,
	[Switch]$directonly
)
BEGIN {
    # if you change the fields remember to update the select statement for output
    $obj = New-Object PSObject -Property @{ 
                    Name = $null
                    SamAccountName = $null
                    Manager = $null
                    EmailAddress = $null 
                 }
    $obj.psobject.typenames.insert(0, 'daveb.ADReports')

}

PROCESS
{
	foreach ($Account in $Identity)
	{
	    # Get the DirectReports
	    Write-Verbose -Message "[PROCESS] Account: $Account"
	    $user = Get-Aduser -identity $Account -Properties directreports 
        $reports = $user.directreports

        foreach ($report in $reports){
            write-verbose ("Report: {0}" -f $report)

		    $direct = Get-ADUser -Identity $report -Properties mail, manager,directreports
            $obj.name = $direct.name
            $obj.SamAccountName = $direct.samaccountname
            $obj.emailaddress = $direct.mail
            $obj.Manager = ($direct.manager  -replace "(CN=)(.*?),.*",'$2')
            
            Write-Output $obj | select Name,SamAccountName,EmailAddress,Manager

			If (-not ($PSBoundParameters['DirectOnly']) -and $direct.directreports) {
                write-verbose ("Recursing for {0}" -f $direct.Name)
                Get-ADReports -Identity $direct.samaccountname
            }
        }# foreach direct
		
    }#foreach account
		

} #process
END{}
}