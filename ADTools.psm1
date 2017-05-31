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
                                                                        $prop.Add("LastLogon",[DateTime]::FromFileTime($user."lastlogontimestamp"))
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
                                                "LastLogon" = [DateTime]::FromFileTime($user."lastlogontimestamp");
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



function get-LAPSCred {
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

BEGIN {}


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