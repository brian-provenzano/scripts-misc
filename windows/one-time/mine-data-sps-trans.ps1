$dataSource = “.”
$user = “”
$pwd = “"
$database = “”
$connectionString = “Server=.;Database=$database;Integrated Security=true;”

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
#gets all districts and schools that are active
$query = “select 
DISTRICT_RECID as districtid, 
district.Name as districtname, school.Name as schoolName, school.SCHOOL_RECID as schoolid, school.Number as schoolnumber
 from (district
inner join school on district.DISTRICT_RECID = SCHOOL.DistrictID)
where district.StatusID = 1 and school.StatusID = 1
order by DISTRICT.name"


$innerVisaDataQuery = "select 
count(*) as totalPayments,
sum(TransactionFee + PaymentAmount + FeeAmount) as totalVolume
from 
([TRANSACTION] inner join PROGRAM_PAYMENT on [TRANSACTION].TRANSACTION_RECID = PROGRAM_PAYMENT.TransactionID)
where [TRANSACTION].Transaction_StatusID = 4
and Payment_MethodID = 2
and SWITCHOFFSET(TODATETIMEOFFSET([transaction].TransactionDateUTC, '+00:00'), '-07:00')
BETWEEN SWITCHOFFSET(TODATETIMEOFFSET('07-01-2014', '+00:00'), '-07:00')
AND SWITCHOFFSET(TODATETIMEOFFSET('07-31-2014', '+00:00'), '-07:00')
and PROGRAM_PAYMENT.SchoolID = "

$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$table = new-object “System.Data.DataTable”
$table.Load($result)
#new table to fill 
$destinationTable = new-object “System.Data.DataTable”
$districtID = New-Object system.Data.DataColumn districtid,([string])
$districtName = New-Object system.Data.DataColumn districtName,([string])
$schoolName = New-Object system.Data.DataColumn schoolName,([string])
#$schoolID = New-Object system.Data.DataColumn schoolid,([string])
$schoolNumber = New-Object system.Data.DataColumn schoolNumber,([string])
$PaymentCount = New-Object system.Data.DataColumn checkPaymentCount,([string])
$Volume = New-Object system.Data.DataColumn checkVolume,([string])

$destinationTable.Columns.Add($districtID)
$destinationTable.Columns.Add($districtName)
$destinationTable.Columns.Add($schoolName)
#$destinationTable.Columns.Add($schoolID)
$destinationTable.Columns.Add($schoolNumber)
$destinationTable.Columns.Add($PaymentCount)
$destinationTable.Columns.Add($Volume)

$count = 0
write-host $table.Rows.Count
foreach($row in $table.Rows){ 
            #start
            $destinationTableRow = $destinationTable.NewRow()


            $destinationTableRow.districtid = $row.districtid
            $destinationTableRow.districtName = $row.districtname
            $destinationTableRow.schoolName = $row.schoolname
           # $destinationTableRow.schoolid = $row.schoolid
            $destinationTableRow.schoolNumber = $row.schoolnumber


        #get transdata here
        $cmd = $connection.CreateCommand()       
        $cmd.CommandText = ($innerVisaDataQuery + $row.schoolid)
        $rst = $cmd.ExecuteReader()
        $tmpTable = new-object “System.Data.DataTable”
        $tmpTable.Load($rst)
        $cnt = 0
        foreach($row in $tmpTable.Rows){ 
            
            $destinationTableRow.checkPaymentCount = $row.totalPayments
            if([string]::IsNullOrEmpty($row.totalVolume)){
           $destinationTableRow.checkVolume = "0"
            } else{
             $destinationTableRow.checkVolume = $row.totalVolume
            }
            
             
          $cnt++
        }

            #done
            $destinationTable.Rows.Add($destinationTableRow)
   
   $count++
}

  

#Display the results
#$destinationTable | format-table -AutoSize 
#write-host $getPath
$csv = $destinationTable | export-csv C:\Users\brianprovenzano\Desktop\SPS-volume-statistics-checkvolume-july2014.csv -noType
