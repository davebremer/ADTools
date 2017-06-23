# ADTools
This is mostly a collection of AD helper tools for a Service Desk person. The functions mainly return information.

## Functions
### Get-UserDetails
Search for a user object in AD by a person's name or there username (SamID or SamAccountName) with wildcards. A number of flags allow the mix and match of fields. If no filtering flags are used then the full list is output. Otherwise you can build up the output by adding specific fields as flags
