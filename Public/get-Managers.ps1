function Get-Managers {
<#
.SYNOPSIS
	Gets the reporting chain for a person
	
.DESCRIPTION
	returns the persons name and an array containing their reporting lines
    The field ReportingLine is an array of Microsoft.ActiveDirectory.Management.ADUser
	
	
.PARAMETER Identity
    the username or Distinguished name for a person
	
	
.EXAMPLE
 get-managers myname123
 
 Returns columns name, reportingline 

.EXAMPLE
 get-managers abc123 | select -expandProperty reportingline | select name

 Returns a list of managers for the username abc123


.NOTES	
Author: Dave Bremer
Date: 2020/6/3

	
#>
#Requires -Modules ActiveDirectory

[CmdletBinding()]
PARAM (
	[Parameter(Mandatory)]
	[String[]]$Identity,
	[Switch]$lineManager
)
BEGIN {
    # if you change the fields remember to update the select statement for output
    $obj = New-Object PSObject -Property @{ 
                    Name = $null
                    ReportingLine = $null 
                 }
    $obj.psobject.typenames.insert(0, 'daveb.Managers')

}

PROCESS
{
	foreach ($Account in $Identity)
	{
        
        $obj.ReportingLine = @()
        $thisuser = get-aduser -identity $account -Properties manager
        $obj.Name = $thisuser.Name
        
        while ($thisuser.manager){
            
            $obj.ReportingLine += $thisuser
            if (-not $linemanager) { 
                $thisuser = get-aduser -identity $thisuser.manager -Properties manager
            } else {
                break
            }
        
        }
        if (-not $linemanager) {$obj.ReportingLine += $thisuser } #get the last user in the list
        Write-Output $obj
    }#foreach account
		

} #process
END{}
}
