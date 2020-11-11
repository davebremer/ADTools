function Get-UserGroupMembership {
<#
.SYNOPSIS
 Return a list of groups that the user is a member of.

.DESCRIPTION
 Return a list of groups that the user is a member of. Script takes can take an array of usernames. 

.PARAMETER UserName
The username, or a list of usernames

.EXAMPLE
 Get-UserGroupMembership myusername, yourusername
 Outputs details of groups from myusername and yourusername

 .EXAMPLE
 Get-UserGroupMembership myUserName | select UserName,GroupName | Out-GridView
 Displays the group membership in gridview. For a permanent output consider changing Out-Gridview to something like
 "export-csv t:\myfolder\groupnames.csv -NoTypeInformation"

 .EXAMPLE
 Get-UserGroupMembership myUserName | where mail -ne $null
 Will list all of the groups which are mail enabled


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
                    Info = $null
                 }
    $obj.psobject.typenames.insert(0, 'daveb.UserGroupMembership')

}

PROCESS {

    foreach ($User in $username){
        #$Groups = (get-aduser $user -properties memberof | select -ExpandProperty memberof)
        $groups = Get-ADPrincipalGroupMembership $user

        $obj.UserName = $User
        foreach ( $Group in $Groups) { 
        
            $g = get-adgroup $Group -Properties mail,description,info
            write-verbose $g
            write-verbose ("Category: {0}, Scope: {1}" -f $g.GroupCategory, $g.GroupScope)

            $obj.GroupName = $g.name
            $obj.GroupDN = $Group
            $obj.GroupCategory = $g.GroupCategory
            $obj.GroupScope = $g.GroupScope
            $obj.Mail = $g.mail
            $obj.Description = $g.description

            if ($g.info){
                $obj.Info = ($g.info -replace("`r`n"," | "))
            } else {
                $obj.Info = $null
            }
            
            

             
            Write-Output $obj
        
        }
    }
}

END{}

}



#Get-UserGroupMembership admindzb 