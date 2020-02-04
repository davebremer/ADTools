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

.EXAMPLE
    (Get-LAPSCred pc-1234 ).GetNetworkCredential().password
    Returns the plaintext of the laps password

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
        $cred = New-Object System.Management.Automation.PSCredential ("$computername\administrator",$secpassword)
        $cred 
        } else {  #error
        if ($adminpassword){
            write-error ("{0} is in AD but has no LAPS password" -f $ComputerName)
            } else { write-error ("{0} not in AD" -f $ComputerName)}
    }
}

END{}
}