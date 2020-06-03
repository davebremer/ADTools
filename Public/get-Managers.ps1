function Get-Managers {
<#
.SYNOPSIS
	Lists the reporting chain for a person
	
.DESCRIPTION
	lists as name, manager pairs the reporting chain
	
	
.PARAMETER Identity
    the username or Distinguished name for a person
	
	
.EXAMPLE
 get-managers myname123

 name           Manager       
----           -------       
Alice Abrims   Bob Black
Bob Black      Chris Clod
Chris Clod     Dave Davis
Dave Davis     Edgar Evans

.NOTES	
Author: Dave Bremer
Date: 2020/6/3

#todo
It'd be better to have a single record spit out with one field being a collectio/array of managers
then take an array of inputs
	
#>
#Requires -Modules ActiveDirectory

[CmdletBinding()]
PARAM (
	[Parameter(Mandatory)]
	[String]$Identity,
	[Switch]$lineManager
)
BEGIN {
    

}

PROCESS
{
	foreach ($Account in $Identity)
	{
        $thisuser = get-aduser -identity $account -Properties manager
        while ($thisuser.manager){
           $thisuser | select name,@{n="Manager";e={$_.Manager -replace "(CN=)(.*?),.*",'$2'}}
           if (-not $linemanager) { 
                $thisuser = get-aduser -identity $thisuser.manager -Properties manager
           } else {
                break
           }
        }
    }#foreach account
		

} #process
END{}
}
