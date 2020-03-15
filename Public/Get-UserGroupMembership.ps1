function Get-UserGroupMembership {
<#
.SYNOPSIS
 Return a list of groups that the user is a member of.

.DESCRIPTION
 Return a list of groups that the user is a member of. Script takes can take an array of usernames. Returns an object consisting or
 username, Group name, and Group distinguished name

.PARAMETER UserName
The username, or a list of usernames



.EXAMPLE
 Get-UserGroupMembershiip myusername, yourusername

.NOTES
 Author: Dave Bremer
 Date: 9 Feb 2020
 Revisions:
 

#>

    [cmdletBinding()]
    Param ([Parameter (
            Mandatory=$True,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            #[ValidateScript({Get-ADUser $_})]
            [string[]] $UserName
            )

BEGIN {
    $obj = New-Object PSObject -Property @{ 
                    User = $null
                    GroupName = $null
                    GroupDN = $null
                 }
    $obj.psobject.typenames.insert(0, 'daveb.UserGroupMembership')

}

PROCESS {
    foreach ($User in $username){
        $Groups = (get-aduser $user -properties memberof | select -ExpandProperty memberof)

        $obj.User = $User
        foreach ( $Group in $Groups) { 
            $obj.GroupName = ($Group -split "," | select-string "CN=") -replace "CN="
            $obj.GroupDN = $Group

             
            Write-Output $obj
        
        }
    }
}

END{}

}



#Get-UserGroupMembership admindzb 