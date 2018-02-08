$dataSource = “.\SQLEXPRESS”
$user = “”
$pwd = “"
$database = “”
$connectionString = “Server=.\SQL2012;Database=$database;Integrated Security=true;”

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$query = “select
DISTRICT_RECID, Name, ZipCode, [State],
time_zone.[Description] AS timezone,
[STATUS].[Description] as status,
district_parameter.ParameterValue as parametervalue,
district_parameter.Parametername as parametername
from ((district inner join TIME_ZONE on district.Time_ZoneID = TIME_ZONE.TIME_ZONE_RECID) 
inner join STATUS on DISTRICT.StatusID = STATUS.STATUS_RECID)
inner join  DISTRICT_PARAMETER on district.DISTRICT_RECID = DISTRICT_PARAMETER.DistrictID
where district.StatusID = 1
and DISTRICT_PARAMETER.Parametername = 'Address1'
or DISTRICT_PARAMETER.ParameterName = 'Address2'
or DISTRICT_PARAMETER.ParameterName = 'City'
order by district.name, parametername"

$innerQuery = "select username, emailaddress, districtid
from [user] inner join district on district.district_recid = [user].districtid 
where role = 2 and district.StatusID = 1 and [user].StatusID = 1 and district_recid <> 1
and districtid = "

$schoolInnerQuery = "select count(*) AS schoolcount from school where districtid = "


$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()

$table = new-object “System.Data.DataTable”
$table.Load($result)


#new table to fill 
$destinationTable = new-object “System.Data.DataTable”
$districtID = New-Object system.Data.DataColumn id,([string])
$districtName = New-Object system.Data.DataColumn name,([string])
$districtAddress = New-Object system.Data.DataColumn address,([string])
$districtCity = New-Object system.Data.DataColumn city,([string])
$districtState = New-Object system.Data.DataColumn state,([string])
$districtZipcode = New-Object system.Data.DataColumn zipcode,([string])
$districtTimezone = New-Object system.Data.DataColumn timezone,([string])
$districtContacts = New-Object system.Data.DataColumn contacts,([string])
$districtSchools =  New-Object system.Data.DataColumn schools,([string])
$destinationTable.Columns.Add($districtID)
$destinationTable.Columns.Add($districtName)
$destinationTable.Columns.Add($districtAddress)
$destinationTable.Columns.Add($districtCity)
$destinationTable.Columns.Add($districtState)
$destinationTable.Columns.Add($districtZipcode)
$destinationTable.Columns.Add($districtTimezone)
$destinationTable.Columns.Add($districtContacts)
$destinationTable.Columns.Add($districtSchools)

$currentID = -1
$count = 0
write-host $table.Rows.Count
foreach($row in $table.Rows){ 
#write-host $row.DISTRICT_RECID
    if($row.DISTRICT_RECID -eq $currentID){
    Write-Host ("samerow" + $currentID + "---count" + $count + ">>>>>>>" + $row.parametername)
    #same district fill current row
        if($row.Parametername -eq "Address2"){
            $address = ($address + " " + $row.parametervalue)          
            #write-Host ("----" + $row.parametervalue)
        }
        if($row.Parametername -eq "City"){
            $city = $row.parametervalue         
           # write-Host ("----" + $row.parametervalue)
        }

        #stupid hack
        if($count -eq ($table.Rows.Count - 1)){
            #write-host "SEAL THE ROW"
            $destinationTableRow.address = $address.Trim()
            $destinationTableRow.city = $city.Trim()
            $destinationTable.Rows.Add($destinationTableRow)
        }

    } else{

    $currentID = $row.DISTRICT_RECID
    Write-Host ("newrow" + $currentID + "---count" + $count)
    $destinationTableRow.address = $address.Trim()
    $destinationTableRow.city = $city.Trim()

    #new district create new row
    if($count -ne 0){
        write-host "ADD THE ROW"
        $destinationTable.Rows.Add($destinationTableRow)
    }  
    $destinationTableRow = $destinationTable.NewRow()
    write-host "CREATE  ROW"
    $address = ""
    $address = ($address + $row.parametervalue)
    $destinationTableRow.id = $row.DISTRICT_RECID
    $destinationTableRow.name = $row.name
    $destinationTableRow.zipcode = $row.zipcode
    $destinationTableRow.state = $row.state
    $destinationTableRow.timezone = $row.timezone 

    #get contacts here
        $cmd = $connection.CreateCommand()       
        $cmd.CommandText = ($innerQuery + $currentID)
        $rst = $cmd.ExecuteReader()
        $tmpTable = new-object “System.Data.DataTable”
        $tmpTable.Load($rst)
        $contacts = ""
        $cnt = 0
        foreach($row in $tmpTable.Rows){ 
            #write-host $currentID $row.emailaddress
            if($cnt -ne 0){
             $contacts = ($contacts + "," + $row.emailaddress)
             } else{
             $contacts = $row.emailaddress
             }
             $cnt++
        }
        $destinationTableRow.contacts = $contacts

        #get contacts here
        $cmd2 = $connection.CreateCommand()       
        $cmd2.CommandText = ($schoolInnerQuery + $currentID)
        $rst2 = $cmd2.ExecuteReader()
        $tmpTable2 = new-object “System.Data.DataTable”
        $tmpTable2.Load($rst2)

        $destinationTableRow.schools = $tmpTable2.schoolcount

    }

      
    
$count++
}

#Display the results
#$destinationTable | format-table -AutoSize 
#write-host $getPath
$csv = $destinationTable | export-csv C:\Users\brianprovenzano\Desktop\SPS-demographics-info-with-schools.csv -noType
