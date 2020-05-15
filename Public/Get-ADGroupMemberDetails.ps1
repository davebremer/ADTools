function Get-ADGroupMemberDetails {
<#
.SYNOPSIS
 Returns the users who are members of groups, with details of the users

.DESCRIPTION
 Returns the users who are members of groups, with details of the users.

 The groups can be a single group, an array of groups, or include wildcards (in a string).

 This function does recurse and expand into groups which are members of a group. That might get ugly.
 One thing to note is that if a group does have a member group, and a user is a member of both, then
 that user will appear multiple times, with full duplicates being listed. I think there's a bug causing
 the full duplicates - can't quite spot it.
  
 The detail include:
    GroupName
    MemberName
    UserDisplayName
    Enabled
    Office
    Manager
    MemberType
    EmailAddress
 

.PARAMETER GroupName
 The name of the groups to check. This can be an array of groups and works with wildcards (in string)


.EXAMPLE
 Get-ADGroupMemberDetails gumboot
 will return all the members of the group "gumboot"

.EXAMPLE
 Get-ADGroupMemberDetails gumboot, socks
 will return all the members of the group "gumboot" and "socks"

.EXAMPLE
 Get-ADGroupMemberDetails "gum*"
 will return all the members of the group "gumboot" and "gumball" an any other group which begin with "gum"

.NOTES
 Author: Dave Bremer
 Date: 2020/9/4
 Revisions:
 
 

#>

    [cmdletBinding()]
    Param ([Parameter (
            Mandatory=$True,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            #[ValidateScript({Get-ADGroup $_})]
            [string[]] $GroupName
            )

BEGIN {
    $obj = New-Object PSObject -Property @{ 
                    MemberName = $null
                    UserDisplayName = $null
                    GroupName = $null
                    Enabled = $null
                    Office = $null
                    Manager = $null
                    MemberType = $null
                    EmailAddress = $null
                    
                 }
    $obj.psobject.typenames.insert(0, 'daveb.ADGroupMemberDetails')

} #BEGIN

PROCESS {
    Write-Verbose ("Groupname: {0}" -f $GroupName)
    $thegroups = (get-adgroup -filter "Name -like '$groupname'")
    #get-adgroup -filter "SamAccountName -like '$groupname'"
    Write-Verbose ("thegroups: {0}" -f ($thegroups | measure).Count)

    foreach ($group in $thegroups) {
        $allmembers = Get-ADGroupMember $group.samaccountname

        foreach ($member in $allmembers) { 
            $obj.GroupName = $group.name
            $obj.MemberName = $null
            $obj.UserDisplayName = $null
            $obj.Manager = $null
            $obj.Office = $null
            $obj.Enabled = $null
            $obj.MemberType = $null
            $obj.EmailAddress = $null

             if ($member.objectClass -eq "user") { 
                Write-Verbose $member.SamAccountName
                 $userobj = get-aduser $member.samaccountname -properties *
                 $obj.MemberName = $userobj.Samaccountname
                 $obj.UserDisplayName = $userobj.name
                 $obj.Office = $userobj.office
                 $obj.Enabled = $userobj.Enabled
                 $obj.Manager = ($Userobj.Manager -replace "(CN=)(.*?),.*",'$2')
                 $obj.memberType = "User"
                 $obj.EmailAddress = $userobj.EmailAddress

            } else { # a group member is itself a group
            # would recursion work I wonder?
            # why yes, yes it does
            # what could possibly go wrong?
            # duplicates were the least of my worry - but duplicates there are
                
                $Obj.MemberName = $member.SamAccountName
                $obj.MemberType = "Group"
                Get-ADGroupMemberDetails $member.name
            }
            Write-Output $obj 
        
        } 
         
        
    } 

} #POCESS

END {} #END
}