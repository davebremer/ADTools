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
 Adds the Office telephone and mobile phone to the output

.PARAMETER UName
 Adds the Username to the output

.PARAMETER Empid
 Adds the Employee ID to the output

.PARAMETER Dept
 Adds the department to the output
            
.PARAMETER HomeDir
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
 get-UserDetails -UserName "DNABC12"
 Will return the details of a user with the username DNABC12

.EXAMPLE
 get-UserDetails -SamId "DNABC12"
 Will return the details of a user with the username DNABC12

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
            #[switch] $empid,
            [switch] $dept,
           # [switch] $HomeDir,
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
                            {$PSBoundParameters.Keys -contains 'Tel'} {$prop.Add("Extension",$User.OfficePhone)
                                                                        $prop.add("Mobile",$User.MobilePhone)
                                                                        $prop.add("ipPhone",$User.ipPhone)
                                                                        }

                            {$PSBoundParameters.Keys -contains 'UName'} {$prop.add("Username", $user.SamAccountName)}

                            {$PSBoundParameters.Keys -contains 'Empid'} {$prop.Add("Empid", $User.EmployeeID)}
                            
                            {$PSBoundParameters.Keys -contains 'Dept'} {$prop.Add("Dept", $User.Department)}

                            #{$PSBoundParameters.Keys -contains 'HomeDir'} {$prop.Add("HomeDir", $User.HomeDirectory)}
                            {$PSBoundParameters.Keys -contains 'UPN'} {$prop.Add("UPN", $User.UserPrincipalName)}
                            {$PSBoundParameters.Keys -contains 'Manager'} {$prop.Add("Manager", ($User.Manager -replace "(CN=)(.*?),.*",'$2'))}
                            {$PSBoundParameters.Keys -contains 'Pass'} {$prop.Add("PassExpired", $User.PasswordExpired)
                                                                        $prop.Add("PassLastSet", $User.PasswordLastSet)
                                                                        $prop.Add("Enabled", $User.Enabled)
                                                                        $prop.Add("LockedOut",$user.LockedOut)
                                                                        }


                            {$PSBoundParameters.Keys -contains 'Address'} { $prop.Add("Title", $User.Title)
                                                                            $prop.Add("Dept", $User.Department)
                                                                            $prop.Add("Office", $user.Office)
                                                                            $prop.Add("OfficeName", $User.physicalDeliveryOfficeName)
                                                                            $prop.Add("st", $user.st)
                                                                            $prop.Add("State",$user.State)
                                                                            $prop.Add("StreetAddress",$user.StreetAddress)
                                                                            }
                                                                                                 
                            default {$prop = @{  "OU" = $User.CanonicalName;
                                                "Name" = $User.DisplayName;
                                                "Email" = $User.EmailAddress;
                                                #"EmpID" = $User.EmployeeID;
                                                "Title" = $User.Title;
                                                "Dept" = $User.Department;
                                                "Office" = $user.Office;
                                                "OfficeName" = $User.physicalDeliveryOfficeName;
                                                "st" = $user.st;
                                                "State" = $user.State;
                                                "StreetAddress" = $user.StreetAddress;
                                                #"HomeDir" = $User.HomeDirectory;
                                                "Manager" = $User.Manager -replace "(CN=)(.*?),.*",'$2';
                                                "Mobile" = $User.MobilePhone
                                                "Extension"= $User.OfficePhone;
                                                "Created" = $User.whenCreated;
                                                "PassExpired" = $User.PasswordExpired;
                                                "PassLastSet" = $User.PasswordLastSet;
                                                "Username" = $user.SamAccountName;
                                                "Enabled" = $user.Enabled;
                                                "LockedOut" = $user.LockedOut;
                                                #"ProfilePath" = $user.ProfilePath
                                                "UPN" = $user.UserPrincipalName;
                                                "opPhone" = $user.ipPhone
                                               } # prop
                                } #default
                        } #switch

                        $obj = New-Object -TypeName PSObject -Property $prop
                        $obj.psobject.typenames.insert(0, 'daveb.systools.userdetails')


                        Write-Output $obj 

                      #  if ($OpenHD) { start $user.HomeDirectory } 
                      #  if ($OpenP) { start $user.ProfilePath } 

                    } #foreach $userobj
            } #foreach $item
                
        } #Process

    END{}
}

function Get-LastLogonToAD {
<#
.SYNOPSIS
 Gets the last login time for a username by querying all domain controllers

.DESCRIPTION
 Gets the last login time for a username by querying all domain controllers

.PARAMETER UserName
Username to search


.EXAMPLE
Get-LastLogonToAD -username dndzbj0
Returns the last login time for dndzbj0

.NOTES
 Author: Dave Bremer
 

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
    write-verbose "looking for $username"
}

PROCESS {
         
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
            "LastLogon" = [DateTime]::FromFileTime($user.lastlogon)
            } # prop
                               

    $obj = New-Object -TypeName PSObject -Property $prop
    $obj.psobject.typenames.insert(0, 'sdhb.adtools.userdetails')
    Write-Output $obj 
}
END{}
}

function Remove-ADCompDNS {
<#
.SYNOPSIS
 Remove a objects and DNS entries for computers that are being disposed

.DESCRIPTION
 Removes both the computer object from AD and the DNS entries for computers being disposed

.PARAMETER ComputerName
The name, or list of names, of computers to removeimport-module
-comp

.EXAMPLE
Remove-AdCompDNS -computername PC159876
Will remove PC159876 from AD and from DNS

.EXAMPLE
get-content h:\pclist.txt | Remove-ADCompDNS 
Removes computers in the file from both AD and DSN. Will request confirmation for each

.EXAMPLE
get-content h:\pclist.txt | Remove-ADCompDNS -confirm:$false
Will NOT ask for confirmation so be sure and be careful

.EXAMPLE
gc h:\dispose.txt | remove-AdCompDNS -confirm:$false | ft -auto -wrap
A nicer format of output of the output
 


.NOTES
 Author: Dave Bremer
 

#>
[cmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
Param ([Parameter (
                Mandatory = $TRUE, 
                ValueFromPipeLine = $TRUE,
                ValueFromPipelineByPropertyName = $TRUE
                )]
            [Alias('cn')] 
            [string[]] $ComputerName
        )

BEGIN {}


PROCESS{            
    foreach ($comp in $computername) {
        #Remove AD Computer

        if ($pscmdlet.ShouldProcess(("Remove from AD and DNS: {0}" -f $comp,$group))) {
        #remove AD object - use try/catch for object existing
            try {
                Remove-ADComputer -identity $comp -ErrorAction Stop
                $LogAction = @{"Date" = get-date;
                                "Action" = "Removed from AD";
                                "Name" = $comp
                                "RemovedBy" = $env:username
                                }
                
                $obj = New-Object -TypeName PSObject -Property $LogAction
                $obj.psobject.typenames.insert(0, 'sdhb.script.remove')
                Write-Output $obj
                Export-Csv -Path "\\dnvfile03\infosys$\powershell\logs\remove-adcompdns.csv" -InputObject $obj -NoTypeInformation -Append # requires powershell 3 for append
               
            } catch  { write-warning $_.Exception.Message}

            try{
                Get-DnsServerResourceRecord -ComputerName dnad10 -ZoneName healthotago.co.nz -name $comp -ErrorAction Stop | 
                    Remove-DnsServerResourceRecord -zone healthotago.co.nz -ComputerName dnad10 -confirm:$false -force
                $LogAction = @{"Date" = get-date;
                                "Action" = "Removed from DNS healthotago.co.nz";
                                "Name" = $comp
                                "RemovedBy" = $env:username
                              }
                $obj = New-Object -TypeName PSObject -Property $LogAction
                $obj.psobject.typenames.insert(0, 'sdhb.script.remove')
                Write-Output $obj
                Export-Csv -Path "\\dnvfile03\infosys$\powershell\logs\remove-adcompdns.csv" -InputObject $obj -NoTypeInformation -Append # requires powershell 3 for append
            } catch  { write-warning $_.Exception.Message}
        } #if should process
    } #foreach comp
}

END{}
}