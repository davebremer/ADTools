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
