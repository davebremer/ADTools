function Get-Member2Groups {
<#
.SYNOPSIS
 Find the members of two groups, or members missing from one group that are in the other.

.DESCRIPTION
 Find the members of two groups. If either of the groups are not found the script exits. A switch of -missing will list the members of the first group that are NOT in the second group
 
.PARAMETER Group1
The name of the first group - alias g1

.PARAMETER Group2
The name of the second group - alias g2

.PARAMETER Missing
Tells the script to return the members of Group1 that are missing from Group2

.PARAMETER Stats
Gets a count of the number of users only in the left group, the number only in the right group, and the number in both groups. This makes the -missing switch redundant

.EXAMPLE
get-member2groups -group1 Wibble -group2 Foo

Will find all of the user objects which are members of both the group Wibble and Foo

.EXAMPLE
get-member2groups -group1 Wibble -group2 Foo -missing

Will return all of the user objects which are in Wibble but NOT in Foo

.EXAMPLE
get-member2groups -group1 Wibble -group2 Foo -stats | Format-table -autosize

RightOnly LeftOnly Both
--------- -------- ----
        1       70   19


.NOTES
 Author: Dave Bremer
 Date: 23/9/2015
 Revisions:
 23/6/2017 added stats

#>
    [cmdletBinding()]
    Param ([Parameter (
            Mandatory=$True,
            position = 1,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Get-ADGroup $_})]
            [Alias('g1')]
            [string] $Group1,

            [Parameter (
                Mandatory=$True,
                Position=2,
                ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({Get-ADGroup $_})]
            [Alias('g2')]
            [string] $Group2,

            [switch] $missing,

            [switch] $Stats
            )
BEGIN {}

PROCESS {

    $counter = New-Object PSObject -Property @{
            LeftOnly = 0
            Both = 0
            RightOnly = 0
            }
    $counter.psobject.typenames.insert(0, 'daveb.adtools.GroupStats')

    try {
        write-verbose ("Getting members of group {0}" -f $Group1)
        $G1members = Get-ADGroupMember -identity  $Group1 -recursive -ErrorAction stop
        write-verbose ("{0} has {1} members" -f $Group1,($G1members.count))
    } catch {
        Write-Error $_
        return
    } #try-catch group1 members

    try {
        write-verbose ("Getting members of group {0}" -f $Group2)
        $G2members = Get-ADGroupMember -Identity $Group2 -recursive -ErrorAction stop
        write-verbose ("{0} has {1} members" -f $Group2,($G2members.count))
    } catch {
        Write-Error $_
        return
    } # try-catch group2 members


    #removing this to make adding -missing easier. The efficiency was more academic than experienced anyway
    
    <#

    # Check which group is smaller. Using the smallest for the loop dramatically
    # reduces run time if there's a massive group and a tiny one

    if ($G1members.count -le $G2members.count) {
        Write-Verbose ("{0} is the smallest" -f $Group1)
        $member1 = $G1members
        $member2 = $G2members.SamAccountName
    } else {
        Write-Verbose ("{0} is the smallest" -f $Group2)
        $member1 = $G2members
        $member2 = $G1members.SamAccountName
    }
    #>

    #vars for progress bar
    $ProgCounter = 0
    $tot = $G1members.count

    ForEach ($person in $G1members) {


        #draw progress bar
        $ProgCounter+=1
        $prog=[system.math]::round($ProgCounter/$tot*100,2)
        write-progress -activity ("Remaining: {0}" -f ($tot-$ProgCounter)) -status "$prog% Complete:" -percentcomplete $prog;
        
        if ($G2members.SamAccountName -contains $person.samaccountname){
            #member of both groups
           if ($PSBoundParameters.Keys -notcontains 'missing' -and $PSBoundParameters.Keys -notcontains 'Stats'){ Write-Output $person}
           $Counter.Both++

        } else {
            #Just member of Group1
            if ($PSBoundParameters.Keys -contains 'missing' -and $PSBoundParameters.Keys -notcontains 'Stats'){ Write-Output $person}
            # write-verbose ("NOT found {0}" -f $person.name)
            $Counter.LeftOnly++

        } #if then

    } #for loop

    if ($PSBoundParameters.Keys -contains 'Stats') {
        ForEach ($person in $G2members ) {
            if ($G1members.SamAccountName -notcontains $person.samaccountname) {$counter.RightOnly++}
        }
        Write-Output $counter
    }# if stats
    
} #process
END {}
}
