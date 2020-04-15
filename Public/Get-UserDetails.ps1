# This was my very first script. Its clumsy and really could do with a refresh. Don't judge me :-/
function Get-UserDetails {
<#
.SYNOPSIS
 Get key details of a user object

.DESCRIPTION
 Search for a user object in AD by a person's name or there username (SamID or SamAccountName). A number of flags allow the mix and match of fields. 
 If no filtering flags are used then the (almost) full list is output. Otherwise you can build up the output by adding specific fields as flags.
 The exception to the "full list" as default is the info field. If you want that then you need to specify

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
 Adds a number of password and account related date fields to the output:
    PasswordExpires
    PassLastSet
    Enabled
    LockedOut
    AccountExpiryDate
    PassExpired
    LastLogon
    PasswordRemainingDays

.PARAMETER Info
 Adds the info field ie the notes field

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

.EXAMPLE
 Get-UserDetails -username ABC* -info | select username,name,enabled,LastLogon,AccountExpiryDate,email,info
 will return the selected details including info for any username starting with ABC
 Useful for looking at password expiry for groups of similarly named accounts

.NOTES
 Author: Dave Bremer

 #TODO
 bug with info if blank - the replace moans it can't replace a null. Test for null before ad
 
 

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

            [switch] $Tel, # adds telephone fields - both office and cell
            [switch] $UName, #adds username fields - the variable "username" already used for another paramter to search for samid
            [switch] $EmployeeNumber,
            [switch] $Department,
           # [switch] $HomeDirectory,
            [switch] $manager,
            [switch] $Pass,
            [switch] $Address,
            #[switch] $OpenP,  #open profile dir
            #[switch]$OpenHD #open Home Directory
            [switch] $UPN,
            [switch] $info
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
                Write-Verbose "item: $item"
                switch($Set){
                    "user" { $UserObj = Get-ADUser -filter { name -like $item } -property *,'msDS-UserPasswordExpiryTimeComputed'; break }

                    "samid" { Try { # fatal exception if searching by identity that doesn't exist.
                                    $UserObj = Get-ADUser -filter {samaccountname -like $item} -property *,'msDS-UserPasswordExpiryTimeComputed'; break 
                                    } Catch{ Write-Verbose "nothing found"}
                                } #samid
                } #switch
                
                foreach ( $user in $userobj) {
                    write-verbose "Properties: $Item / $user"
                    
                    # Convert the password expiry calculated date
                    # Refer to https://stackoverflow.com/questions/51165528/contradictory-values-from-active-directory-regarding-password-expiry-datesaw s
                    # Also https://ldapwiki.com/wiki/MsDS-UserPasswordExpiryTimeComputed
                    switch ($User.'msDS-UserPasswordExpiryTimeComputed') {
                        0x7FFFFFFFFFFFFFFF { # for various reasons password never expires (several bit values in user account control can cause this)
                            $PasswordExpires = "Never Expires"
                            $PasswordRemainingDays = "Infinite"
                        } 
                        0 { # pwdLastSet = null or pwdLastSet = 0
                            $PasswordExpires = "Unspecified"
                            $PasswordRemainingDays = "Unspecified"
                        }
                    
                        default {
                            $EndDate = (Get-Date)
                            $PasswordExpires = '{0:dd/MM/yyyy}' -f ([datetime]::FromFileTime($User.'msDS-UserPasswordExpiryTimeComputed'));
                            $PasswordRemainingDays = (new-timespan -start $EndDate -end ([datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed"))).Days;
                        }
                    
                    }
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
                            {$PSBoundParameters.Keys -contains 'Pass'} {
                                                                            $prop.Add("PassExpired", $User.PasswordExpired)
                                                                            $prop.Add("PassLastSet", '{0:dd/MM/yyyy}' -f $User."PasswordLastSet")
                                                                            $prop.Add("Enabled", $User.Enabled)
                                                                            $prop.Add("LockedOut",$user.LockedOut)
                                                                            $prop.Add("LastLogon",[DateTime]::FromFileTime($user."lastlogontimestamp").ToString('d/MM/yyyy'))
                                                                            $prop.Add("PasswordExpires", $PasswordExpires)
                                                                            $prop.Add("PasswordRemainingDays",$PasswordRemainingDays)
                                                                            $prop.Add("AccountExpiryDate", '{0:dd/MM/yyyy}' -f $user."AccountExpirationDate")
                                                                            }


                            {$PSBoundParameters.Keys -contains 'Address'} { $prop.Add("Title", $User.Title)
                                                                            $prop.Add("Department", $User.Department)
                                                                            $prop.Add("Office", $user.Office)
                                                                            $prop.Add("OfficeName", $User.physicalDeliveryOfficeName)
                                                                            $prop.Add("st", $user.st)
                                                                            $prop.Add("State",$user.State)
                                                                            $prop.Add("StreetAddress",$user.StreetAddress)
                                                                            }
                                                                                                
                            default {

                                $prop = @{  "OU" = $User.CanonicalName;
                                                "Name" = $User.DisplayName;
                                                "Email" = $User.EmailAddress;
                                                "EmployeeNumber" = $User.EmployeeNumber;
                                                "AccountExpiryDate" = '{0:dd/MM/yyyy}' -f $user."AccountExpirationDate";
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
                                                "Created" = '{0:dd/MM/yyyy}' -f $User."whenCreated";
                                                "PassExpired" = $User.PasswordExpired;
                                                "PassLastSet" = '{0:dd/MM/yyyy}' -f $User."PasswordLastSet";
                                                
                                                "PasswordExpires" = $PasswordExpires;
                                                "PasswordRemainingDays" = $PasswordRemainingDays;

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

                        #the info field is not added by default as too noisy
                        if ($PSBoundParameters.Keys -contains 'info'){
                                if ($user.info){
                                    $prop.add("info", ($user.info).replace("`r`n"," | "))
                                } else {
                                    $prop.add("info",$null)
                                }
                            }

                        $obj = New-Object -TypeName PSObject -Property $prop
                        $obj.psobject.typenames.insert(0, 'daveb.adtools.userdetails')


                        Write-Output $obj 

                      #  if ($OpenHD) { start $user.HomeDirectoryectory } 
                      #  if ($OpenP) { start $user.ProfilePath } 

                    } #foreach $userobj
            } #foreach $item
                
        } #Process

    END{}
}