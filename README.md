# ADTools
This is mostly a collection of AD helper tools for a Service Desk person. The functions mainly return information.

## Functions
### Get-UserDetails
Search for a user object in AD by a person's name or there username (SamID or SamAccountName) with wildcards. Basically, its a cut-down list from `get-AdUser foo -properties *`. I created and frequently use this rather than `get-ADUser` because of the easy use of wildcards, and I've preselected fields that I find useful. I tend to forget the actual names of some of the AD fields

A number of flags allow the mix and match of fields. If no filtering flags are used then the full list is output. Otherwise you can build up the output by adding specific fields as flags

### Get-LAPSCred
Returns a credential object extracted from LAPS on AD. [Check this page for further info](https://technet.microsoft.com/en-us/mt227395.aspx)

### Get-Member2Groups
Lists the members of two groups, or alternativly with a `-missing` - lists the members of one group who are not in another. This expects the groups to be a list of user objects. 

A `-stats` switch will return a count of the member that are in both groups, just in one group, or just in the other.
##### TODO
rewrite so that it works on groups with computer objects too

###  Get-UserGroupDiff
Find the groups that one AD User is a member of which another user is not. Alternativly, with -match, find the groups that both users are members of.

A `-stats` switch will return a count of the member that are in both groups, just in one group, or just in the other.

### Get-LastLogonToAD
This gets a list of domain controllers and trawls them looking for the last login timestamp. This was written to get past arguments over whether the timestamp on the user object is synched reliably across all domain controllers.
