function Get-UserGroupDiff {
<#
.SYNOPSIS
 Find the groups that are different between users.

.DESCRIPTION
 Find the groups that one AD User is a member of which another user is not. Alternativly, with -match, find the groups that both users are members of

.PARAMETER User1
The name of the first user

.PARAMETER User2
The name of the second user

.PARAMETER Match
Tells the script to return the Groups that both users are a member of. This is ignored is the -Stats flag is used

.PARAMETER Stats
Reports on the:
    * Number of groups unique to the first/left user
    * Number of groups unique to the second/right user
    * Number of groups that both users are a member of


.EXAMPLE
get-UserGroupDiff -User1 Alice -User2 Bob

Will find all of the groups which Alice is a member of that Bob is not

.EXAMPLE
get-UserGroupDiff -User1 Alice -User2 Bob -match

Will return all of the groups which both Alice and Bob are both members of

.EXAMPLE
get-UserGroupDiff -user1 Alice01 -user2 Bob01 -Stats

Returns the count for groups that each is a unique member of and the number that they are both a member of - e.g.

LeftOnly Both RightOnly
-------- ---- ---------
       1   54        25

.NOTES
 Author: Dave Bremer
 Date: 16/6/2017
 Revisions:
 

#>

    [cmdletBinding()]
    Param ([Parameter (
            Mandatory=$True,
            position = 1,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Get-ADUser $_})]
            [string] $User1,

            [Parameter (
            Mandatory=$True,
            position = 2,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Get-ADUser $_})]
            [string] $User2,

            [switch] $Match,

            [switch] $stats
            )

BEGIN {}

PROCESS {

    $U1Groups = (Get-ADUser $User1 -Properties memberof | select -ExpandProperty memberof)
    $U2Groups = (Get-ADUser $User2 -Properties memberof | select -ExpandProperty memberof)

    $counter = New-Object PSObject -Property @{
            LeftOnly = 0
            Both = 0
            RightOnly = 0
            }
    $counter.psobject.typenames.insert(0, 'daveb.adtools.GroupStats')

    
    foreach ($group1 in $U1Groups ) {

        $detail = Get-ADGroup $group1 -Properties Name,DistinguishedName,Description,GroupCategory,GroupScope

        if ($u2groups -contains $group1) {
            
             if ($PSBoundParameters.Keys -contains 'Match' -and $PSBoundParameters.Keys -notcontains 'Stats') { Write-Output $detail}
             $Counter.Both++
        } else {
            if ($PSBoundParameters.Keys -notcontains 'Match' -and $PSBoundParameters.Keys -notcontains 'Stats') {Write-Output $detail}
            $counter.LeftOnly++
            
        }        
       
    } #foreach U1

    if ($PSBoundParameters.Keys -contains 'Stats') {
         foreach ($group2 in $U2Groups ) {
            if ($u1groups -notcontains $group2) {$counter.RightOnly++}
        }

        Write-Output $counter
        
    }
    

}

END{}

}