### TODO ###
#get-adcontacts - currently have to do get-adobject then use ldapfilter
#Get-ADObject -LDAPFilter “objectClass=Contact” 
#



# This was my very first script. Its clumsy and really could do with a refresh. Don't judge me :-Þ
function Get-UserDetails {
<#
.SYNOPSIS
 Get key details of a user object

.DESCRIPTION
 Search for a user object in AD by a person's name or there username (SamID or SamAccountName). A number of flags allow the mix and match of fields. If no filtering flags are used then the full list is output. Otherwise you can build up the output by adding specific fields as flags

.PARAMETER Name
 Search for user object(s) by the person's name. Wildcards are allowed. This is the default if parameters are not named.

.PARAMETER Username
 Search for user object(s) by username. An alias of "SamId" can be used instead of "Username"

#.PARAMETER OpenHD
# Opens the person's home directory in an explorer window #TODO error checking on connection to server.

#.PARAMETER OpenP
# Opens the person's profile directory in an explorer window #TODO error checking on connection to server.

#TODO make one to find and open the Remote Desktop Profile dir

.PARAMETER Tel
 Adds the Office telephone and MobilePhone phone to the output

.PARAMETER UName
 Adds the Username to the output

.PARAMETER EmployeeNumber
 Adds the Employee ID to the output

.PARAMETER Department
 Adds the department to the output
            
.PARAMETER HomeDirectory
 Adds the Home Directory to the output
            
.PARAMETER Manager
 Adds the manager to the output

.PARAMETER Pass
 Adds the PassWordExpired and PasswordLastSet to the output

.EXAMPLE
 get-UserDetails -Name "Alice Roberts", "Ron Rivest"
 Will return details of both Alice Roberts and Ron Rivest

.EXAMPLE
 get-UserDetails -Name "Alice *"
 Will return details of any user whose display name starts with "Alice "

.EXAMPLE
 get-UserDetails "Ron Rivest"
 Will return details of anyone named Ron Rivest

.EXAMPLE
 get-UserDetails -UserName "ABC12"
 Will return the details of a user with the username ABC12

.EXAMPLE
 get-UserDetails -SamId "ABC12"
 Will return the details of a user with the username ABC12

.NOTES
 Author: Dave Bremer
 
 

#>


    [cmdletBinding(DefaultParametersetName="user")]
    Param ([Parameter (
            Mandatory=$True,
            ValueFromPipelineByPropertyName = $TRUE,
            ParameterSetName="samid"
                )]
            [ValidateNotNullOrEmpty()]
            [Alias('SamId')]
            [string[]] $UserName,

            [Parameter (
                Mandatory=$True,
                Position=1,
                ValueFromPipelineByPropertyName = $TRUE,
                ParameterSetName="user"
                )]
            [ValidateNotNullOrEmpty()]
            [string[]] $Name,

            [switch] $Tel, #telephone - both office and cell
            [switch] $UName, #username
            [switch] $EmployeeNumber,
            [switch] $Department,
           # [switch] $HomeDirectory,
            [switch] $manager,
            [switch] $Pass,
            [switch] $Address,
            #[switch] $OpenP,  #open profile dir
            #[switch]$OpenHD #open Home Directory
            [switch] $UPN
            
            )

    BEGIN{        
            $set = $PsCmdlet.ParameterSetName
            Write-Verbose "parameterSet is $set"
                    
            switch($set){
                "user" { $searching = $Name; break }
                "samid" {$searching = $UserName; break }
            } #switch  
              
        }#begin
    

    PROCESS {
            write-verbose "Searching: $searching"
            foreach ( $item in $searching ) {
                switch($Set){
                    "user" { $UserObj = Get-ADUser -filter { name -like $item } -property *; break }

                    "samid" { Try { # fatal exception if searching by identity that doesn't exist.
                                    $UserObj = Get-ADUser -identity $item -property *; break 
                                    } Catch{ Write-Verbose "nothing found"}
                                } #samid
                } #switch
                
                foreach ( $user in $userobj) {
                    write-verbose "Properties: $Item / $user"

                    $prop = @{"Name"=$User.DisplayName}

                    Switch ($PSBoundParameters) {
                            {$PSBoundParameters.Keys -contains 'Tel'} {$prop.Add("OfficePhone",$User.OfficePhone)
                                                                        $prop.add("MobilePhone",$User.MobilePhone)
                                                                        $prop.add("Mobile",$User.Mobile)
                                                                        $prop.add("ipPhone",$User.ipPhone)
                                                                        }

                            {$PSBoundParameters.Keys -contains 'UName'} {$prop.add("Username", $user.SamAccountName)}

                            {$PSBoundParameters.Keys -contains 'EmployeeNumber'} {$prop.Add("EmployeeNumber", $User.EmployeeNumber)}
                            
                            {$PSBoundParameters.Keys -contains 'Department'} {$prop.Add("Department", $User.Department)}

                            #{$PSBoundParameters.Keys -contains 'HomeDirectory'} {$prop.Add("HomeDirectory", $User.HomeDirectoryectory)}
                            {$PSBoundParameters.Keys -contains 'UPN'} {$prop.Add("UserPrincipalName", $User.UserPrincipalName)}
                            {$PSBoundParameters.Keys -contains 'Manager'} {$prop.Add("Manager", ($User.Manager -replace "(CN=)(.*?),.*",'$2'))}
                            {$PSBoundParameters.Keys -contains 'Pass'} {$prop.Add("PassExpired", $User.PasswordExpired)
                                                                        $prop.Add("PassLastSet", $User.PasswordLastSet)
                                                                        $prop.Add("Enabled", $User.Enabled)
                                                                        $prop.Add("LockedOut",$user.LockedOut)
                                                                        $prop.Add("LastLogon",[DateTime]::FromFileTime($user."lastlogontimestamp").ToString('d/MM/yyyy'))
                                                                        }


                            {$PSBoundParameters.Keys -contains 'Address'} { $prop.Add("Title", $User.Title)
                                                                            $prop.Add("Department", $User.Department)
                                                                            $prop.Add("Office", $user.Office)
                                                                            $prop.Add("OfficeName", $User.physicalDeliveryOfficeName)
                                                                            $prop.Add("st", $user.st)
                                                                            $prop.Add("State",$user.State)
                                                                            $prop.Add("StreetAddress",$user.StreetAddress)
                                                                            }
                                                                                                 
                            default {$prop = @{  "OU" = $User.CanonicalName;
                                                "Name" = $User.DisplayName;
                                                "Email" = $User.EmailAddress;
                                                "EmployeeNumber" = $User.EmployeeNumber;
                                                "AccountExpiryDate" = $user.AccountExpirationDate;
                                                "Title" = $User.Title;
                                                "Department" = $User.Department;
                                                "Office" = $user.Office;
                                                "OfficeName" = $User.physicalDeliveryOfficeName;
                                                "st" = $user.st;
                                                "State" = $user.State;
                                                "StreetAddress" = $user.StreetAddress;
                                                "City" = $user.City;
                                                #"HomeDirectory" = $User.HomeDirectoryectory;
                                                "Manager" = $User.Manager -replace "(CN=)(.*?),.*",'$2';
                                                "MobilePhone" = $User.MobilePhone ;
                                                "Mobile" = $User.Mobile;
                                                "OfficePhone"= $User.OfficePhone;
                                                "Created" = $User.whenCreated;
                                                "PassExpired" = $User.PasswordExpired;
                                                "PassLastSet" = $User.PasswordLastSet;
                                                "LastLogon" = [DateTime]::FromFileTime($user."lastlogontimestamp").ToString('d/MM/yyyy');
                                                "Username" = $user.SamAccountName;
                                                "Enabled" = $user.Enabled;
                                                "LockedOut" = $user.LockedOut;
                                                "ProfilePath" = $user.ProfilePath;
                                                "UserPrincipalName" = $user.UserPrincipalName;
                                                "ipPhone" = $user.ipPhone
                                               } # prop
                                } #default
                        
                        } #switch PSBoundParameters

                        $obj = New-Object -TypeName PSObject -Property $prop
                        $obj.psobject.typenames.insert(0, 'daveb.systools.userdetails')


                        Write-Output $obj 

                      #  if ($OpenHD) { start $user.HomeDirectoryectory } 
                      #  if ($OpenP) { start $user.ProfilePath } 

                    } #foreach $userobj
            } #foreach $item
                
        } #Process

    END{}
}



function Get-LAPSCred {
<#
.SYNOPSIS
    Returns a PSCredential object for a computer
 

.DESCRIPTION
    Returns a PSCredential object for a computer
 

.PARAMETER ComputerName
    The hostname of a computer

.EXAMPLE
    $mycred = get-LAPSCred pc-1234
    the variable $mycred can now be used in a credential switch for a command

.EXAMPLE
    $computername = pc-1234
    get-WmiObject win32_logicaldisk -Computername $computername -Credential (get-LAPSCred $computername)

    using the credential directly in a credential switch

.NOTES
 Author: Dave Bremer
 Date: 6/5/2017

 #TODO - gracefully handle error where not in laps, or even in AD

 #tidy up error

#>
[cmdletBinding()]
Param ([Parameter (
                Mandatory = $TRUE, 
                ValueFromPipeLine = $TRUE,
                ValueFromPipelineByPropertyName = $TRUE
                )]
            [Alias('cn')] 
            [string] $ComputerName
        )

BEGIN {
    #check if we can call the necessary command
    if (-not (Get-Command -Name Get-AdmPwdPassword -ErrorAction SilentlyContinue)) {
       throw "Cannot find `"Get-AdmPwdPassword`". You need to import the module AdmPwd.PS for LAPS operations"
    }

}


PROCESS{            
    
    $adminpassword = Get-AdmPwdPassword -ComputerName $computername     
    
    if ($adminpassword.password) {
        $secpassword = ConvertTo-SecureString ($adminpassword | select -expand password) -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential (“$computername\administrator",$secpassword)
        $cred
    } else {  #error
        if ($adminpassword){
            write-error ("{0} is in AD but has no LAPS password" -f $ComputerName)
            } else { write-error ("{0} not in AD" -f $ComputerName)}
    }
}

END{}
}

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

function Get-LastLogonToAD {
<#
.SYNOPSIS
 Gets the last login time for a username by querying all domain controllers. Very slow. Consider using lastlogondate property with get-aduser.

.DESCRIPTION
 Gets the last login time for a username by querying all domain controllers. This takes forever - its really only
 worth running if you doubt the lastlogondate value. That uses lastlogontimestamp which is replicated but can be up to 
 14 days out of date. 

 


.PARAMETER UserName
Username to search


.EXAMPLE
Get-LastLogonToAD -username daveb
Returns the last login time for daveb

.NOTES
 Author: Dave Bremer

 TODO - really should look into some way to parralleise this - workflows perhaps?
 

#>
    [cmdletBinding()]
    Param ([Parameter (
            Mandatory=$True,
            ValueFromPipeLine = $TRUE,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            [Alias('SamID')]
            [string] $UserName
            )

BEGIN{
    $dc = Get-ADDomainController -Filter * | Select-Object name
    $tot = $dc.count
    $user = $null
   
}

PROCESS {
     write-verbose "looking for $username"     
    $counter=0 #for progress bar
    foreach ($c in $dc) {
        #draw progress bar
        $counter+=1
        $prog=[system.math]::round($counter/$tot*100,2)
        write-progress -activity ("Server {0}. {1} servers left to check" -f $c.name,($tot-$counter)) -status "$prog% Complete:" -percentcomplete $prog;
        
        #search server
        try{
            Write-verbose ("Server: {0}, User {1}" -f $c.name,$username)
            $temp = get-aduser -Server $c.name -identity $username -Properties lastlogon
            Write-Verbose $temp

            Write-verbose ("{0} LastLogon {1}" -f $c.name,[DateTime]::FromFileTime($temp.lastlogon))

            if ($user.LastLogon -lt $temp.lastlogon) { 
                $user = $temp.PsObject.Copy() 
                $recent = $c.name
            }
        } catch {
        $recent = $null
        Write-verbose ("Error getting from Server: {0}" -f $c.name)
        
        }
    

    }

          
    $prop = @{"LatestDC" = $recent;
            # really shouldn't change data before output. Think about putting this in a manifest to convert from american to d/m/y on display
            "LastLogon" = [DateTime]::FromFileTime($user.lastlogon).ToString('d/MM/yyyy HH:mm:ss')
            } # prop
                               

    $obj = New-Object -TypeName PSObject -Property $prop
    $obj.psobject.typenames.insert(0, 'daveb.adtools.lastlogon')
    Write-Output $obj 
}
END{}
}

