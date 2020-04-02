function Get-UserGroupMembership {
<#
.SYNOPSIS
 Return a list of groups that the user is a member of.

.DESCRIPTION
 Return a list of groups that the user is a member of. Script takes can take an array of usernames. 

.PARAMETER UserName
The username, or a list of usernames

.EXAMPLE
 Get-UserGroupMembershiip myusername, yourusername

.NOTES
 Author: Dave Bremer
 Date: 9 Feb 2020
 Revisions:
 3 Apr 2020 - added a bunch of fields about group
 

#>

    [cmdletBinding()]
    Param ([Parameter (
            Mandatory=$True,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Get-ADUser $_})]
            [string[]] $UserName
            )

BEGIN {
    $obj = New-Object PSObject -Property @{ 
                    UserName = $null
                    GroupName = $null
                    GroupDN = $null
                    GroupCategory = $null
                    GroupScope = $null
                    Mail = $null
                    Description = $null
                 }
    $obj.psobject.typenames.insert(0, 'daveb.UserGroupMembership')

}

PROCESS {
    foreach ($User in $username){
        $Groups = (get-aduser $user -properties memberof | select -ExpandProperty memberof)

        $obj.UserName = $User
        foreach ( $Group in $Groups) { 
            $g = get-adgroup $Group -Properties mail,description
            write-verbose $g
            write-verbose ("Category: {0}, Scope: {1}" -f $g.GroupCategory, $g.GroupScope)

            $obj.GroupName = $g.name
            $obj.GroupDN = $Group
            $obj.GroupCategory = $g.GroupCategory
            $obj.GroupScope = $g.GroupScope
            $obj.Mail = $g.mail
            $obj.Description = $g.description
            

             
            Write-Output $obj
        
        }
    }
}

END{}

}



#Get-UserGroupMembership admindzb 