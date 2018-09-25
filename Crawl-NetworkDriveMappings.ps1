# Crawl-NetworkDriveMappings.ps1

<#
REQUIREMENTS:

I am looking for a powershell script that will collect user drive network drive mappings on a logon Group Policy object. I will create the group policy and test and provide the sql database. I will also need help with the sql queries to gather information (distinct network drives, etc.).

My project is to move all network drives to a new server. I need to make sure I have setup all the network drives first on the new server. Users have randomly mapped network drives (drive letters do not correspond with a certain path) and I will need to update their mapped network drives to the server. I need to be able to first collect this information and manipulate the data. I believe that the best way to do so will be to collect the information into a SQL database.

The goal of this project would be to:
a) collect the information of all mapped network drives for all the users.
b) gather the information to determine next steps (make sure all new UNC drives are setup on the new server)
c) change the powershell script to query the sql server and update the drive letter on the User's machine.
#>

# REFERENCE: http://michaeljswart.com/2017/07/sql-server-upsert-patterns-and-antipatterns/

$DebugPreference = 'SilentlyContinue' # SilentlyContinue = Supress debug messages, Continue = Show debug messages

# Clear screen
Clear-Host

# PARAMS
$DbServer= 'localhost\SQLEXPRESS' #"fileproject.database.windows.net"
$DbName = 'NetworkDrives' #"FileProject"
$User = 'user' #"nmss_admin"
$Pw = 'pw' #"LuckyCh@rms"

#############
# FUNCTIONS #
#############

function Remove-DriveMappings {
    param( [int]$UserId )

    # Remove drive mapping records for user ...

    $deleteDriveMappingsSql = "DELETE FROM DriveMapping WHERE UserID = $UserId"

    write-debug $deleteDriveMappingsSql
    $cmd.CommandText = $deleteDriveMappingsSql

    $rowsAffected = $cmd.ExecuteNonQuery()
    if ($rowsAffected -eq 0) {
        write-host "No drive mappings found to remove for user '$global:username'"
    }
    else {
        write-host "Removed $rowsAffected drive mappings for user '$global:username'"
    }
}

function Add-User {
    # Add user record if doesn't already exist ...

    $insertUserSql = "INSERT INTO [User] (Username) " +
    "OUTPUT INSERTED.UserID " +
    "SELECT '$username' WHERE NOT EXISTS (SELECT * FROM [User] WHERE Username = '$username')"

    write-debug $insertUserSql
    $cmd.CommandText = $insertUserSql

    $rowsAffected = $cmd.ExecuteNonQuery()
    if ($rowsAffected -eq 0) {
        write-host -NoNewline "Network user '$global:username' already exists"
    }
    else {
        write-host -NoNewline "Added network user '$global:username'"
    }

    # Get user ID for new/existing record ...

    $selectUserSql = "SELECT UserID FROM [User] WHERE Username = '$global:username'"

    #write-debug $selectUserSql
    $cmd.CommandText = $selectUserSql

    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $UserId = $reader['UserID']
    }
    $reader.Close()
    write-host " (UserID=$UserId)"

    return $UserId
}

function Add-UNCPath {
    param( [string]$UNCPath )

    # Add UNC path record if doesn't already exist ...

    $insertUNCPathSql = "INSERT INTO UNCPath (UNCPath) " +
    "OUTPUT INSERTED.UNCPathID " +
    "SELECT '$UNCPath' WHERE NOT EXISTS (SELECT * FROM UNCPath WHERE UNCPath = '$UNCPath')"

    write-debug $insertUNCPathSql
    $cmd.CommandText = $insertUNCPathSql

    $rowsAffected = $cmd.ExecuteNonQuery()
    if ($rowsAffected -eq 0) {
        write-host -NoNewline "UNC path '$UNCPath' already exists"
    }
    else {
        write-host -NoNewline "Added UNC path '$UNCPath'"
    }

    # Get UNC path ID for new/existing record ...

    $selectUNCPathSql = "SELECT UNCPathID FROM UNCPath WHERE UNCPath = '$UNCPath'"

    #write-debug $selectUNCPathSql
    $cmd.CommandText = $selectUNCPathSql

    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $UNCPathId = $reader['UNCPathID']
    }
    $reader.Close()
    write-host " (UNCPathID=$UNCPathId)"

    return $UNCPathId
}

function Add-DriveMapping {
    param( [int]$UserId, [string]$DriveLetter, [string]$UNCPathId, [string]$UNCPath )

    # Add drive mapping record ...

    $insertDriveMappingSql = "INSERT INTO DriveMapping (UserID, DriveLetter, UNCPathID, IsActive) " +
    "OUTPUT INSERTED.DriveMappingID " +
    "SELECT $UserId, '$DriveLetter', $UNCPathId, 1 WHERE NOT EXISTS (SELECT * FROM DriveMapping WHERE UserID = $UserId AND DriveLetter = '$DriveLetter')"

    write-debug $insertDriveMappingSql
    $cmd.CommandText = $insertDriveMappingSql

    $rowsAffected = $cmd.ExecuteNonQuery()
    if ($rowsAffected -eq 0) {
        write-host -NoNewline "Drive mapping '$DriveLetter --> $UNCPath' for user '$global:username' already exists"
    }
    else {
        write-host -NoNewline "Added drive mapping '$DriveLetter --> $UNCPath' for user '$global:username'"
    }

    # Get drive mapping ID for new/existing record ...

    $selectDriveMappingSql = "SELECT DriveMappingID FROM DriveMapping WHERE UserID = $UserId"

    #write-debug $selectDriveMappingSql
    $cmd.CommandText = $selectDriveMappingSql

    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $driveMappingId = $reader['DriveMappingID']
    }
    $reader.Close()
    write-host " (DriveMappingID=$driveMappingId)"

    return $driveMappingId
}

########
# MAIN #
########

# Get current user
$global:username = $env:USERNAME
write-debug $global:username

# Get network drive mappings (exclude hidden drives & Q drive)
$driveMappings = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*" -and $_.DisplayRoot -notlike "*$*" -and $_.Name -ne "Q"}

# Open DB connection
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=$DbServer;Database=$DbName;Integrated Security=False;User ID=$User;Password=$Pw;"
$conn.Open()

$global:cmd = New-Object System.Data.SqlClient.SqlCommand
$global:cmd.connection = $global:conn

$userId = Add-User

Remove-DriveMappings -UserId $userId

foreach ($mapping in $driveMappings) {
    $UNCPathId = Add-UNCPath -UNCPath $mapping.DisplayRoot
    $driveMappingId = Add-DriveMapping -UserId $userId -DriveLetter $mapping.Name -UNCPathId $UNCPathId -UNCPath $mapping.DisplayRoot
}

# Closes DB connection
$conn.Close()