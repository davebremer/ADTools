function Get-aaduserMfaMethods {
<#
.SYNOPSIS
   Returns the various MFA methods set up for a user identified by UPN 
 

.DESCRIPTION
  Returns the various MFA methods set up for a user identified by UPN

.PARAMETER UserPrincipalName
 the UserPrincipalName of the accounts being checked

.EXAMPLE
 Get-aaduserMfaMethods alice@company.com, bob@company.com
 Returns the methods used by Alice and Bob

.EXAMPLE
 Get-ADUser -filter "name -like '*Smith*'" | select userprincipalname | Get-aaduserMfaMethods | where defaultmethod -eq $true
 Gets the default methods of anyone with "Smith" as part of their name
 
.NOTES
 Author: Dave Bremer
 Date: 2020/9/14
 Revisions:
 
 #todo this would be a good one to set in manifest to limit displayed fields from object

#>

    [cmdletBinding()]
    Param ([Parameter (
            Mandatory=$True,
            ValueFromPipelineByPropertyName = $TRUE
                )]
            [ValidateNotNullOrEmpty()]
            #[ValidateScript({Get-ADGroup $_})]
            [string[]] $userprincipalname
            )

BEGIN {
    #Check for a connection
    try {
        Write-Verbose "Already connected"
        Get-MsolDomain -ErrorAction Stop > $null
    } Catch {
        Write-Output "Connecting to Azure..."
        Connect-MsolService
    }

    #set up the object
    $obj = New-Object PSObject -Property @{ 
                    
                    UserPrincipalName = $null
                    DisplayName = $null
                    MFAMethod = $null
                    DefaultMethod = $null
                    MFAAlternativePhoneNumber = $null
                    MFAPhoneNumber = $null
                    MFAemail = $null
                    
                    
                 }
    $obj.psobject.typenames.insert(0, 'daveb.AADUserMFANethods')

} #BEGIN

PROCESS {
    foreach ($u in $userprincipalname) {
        
        $theUser = Get-MsolUser -UserPrincipalName $u

        $obj.UserPrincipalName = $theUser.UserPrincipalName
        $obj.DisplayName = $theUser.DisplayName
        $obj.MFAPhoneNumber = $theUser.StrongAuthenticationUserDetails.PhoneNumber
        $obj.MFAAlternativePhoneNumber = $theUser.StrongAuthenticationUserDetails.AlternativePhoneNumber
        $obj.MFAemail = $theUser.StrongAuthenticationUserDetails.email
        
        $methods = ($theUser | select -ExpandProperty StrongAuthenticationmethods)
        foreach ($method in $methods) {
            $obj.MFAMethod = $method.MethodType
            $obj.DefaultMethod = $method.IsDefault

            #select here is bad style :(
            Write-Output $obj | select Displayname,UserPrincipalName,MFAPhoneNumber, MFAAlternativePhoneNumber,MFAemail, MFAMethod,DefaultMethod
        }

    }
}

END{}

}