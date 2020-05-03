<#
        .SYNOPSIS
        OWL CM160 .sqlite to InfluxDB
  
        .DESCRIPTION
        This Script will read from the OWL CM160 .sqlite database, parse all the results and send them directly to InfluxDB. Once there, you can download the next Dashboard to have a full visibility of your Energy Consumption and Cost.
	
        .Notes
        NAME:  owlCM160_Influx.ps1
        LASTEDIT: 03/05/2020
        VERSION: 0.3
        KEYWORDS: InfluxDB, OWL CM160, Energy Monitor
   
        .Link
        You can follow me on https://jorgedelacruz.es/
        Or for an English version, please follow me on https://jorgedelacruz.uk
 
 #Requires PS -Version 3.0
 #Requires System.Data.SQLite, please come here and download the version according to your .NET Framework - https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki (If running +4.6 version, just download then the version for 4.6)    
 #>

# System variables, on here you need to replace the next ones with your own paths, IPs, pass, etc.
#By default the SystemDataSQLLitePath on mi case was C:\Program Files\System.Data.SQLite\2015\bin\System.Data.SQLite.dll
$SystemDataSQLLitePath="YOURPATHTOTHESQLLITEASSEMBLY" 
$NumberArray="THEMINUTESYOUWANTTORETRIEVE"
$InfluxDBURL="https://YOURINFLUXDBSERVER"
$InfluxDBPort="8086"
$InfluxDBDB="YOURINFLUXDB"
$InfluxDBUser='YOURINFLUXUSER'
$InfluxDBPass='YOURINFLUXPASS' | ConvertTo-SecureString -asPlainText -Force
$cred=New-Object System.Management.Automation.PSCredential($InfluxDBUser,$InfluxDBPass)

# System variables, on here you need to replace the next ones with your own paths, IPs, pass, etc.
Add-Type -Path "$SystemDataSQLLitePath"
$con = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$con.ConnectionString = "Data Source=C:\ProgramData\2SE\2SEData.db"
$con.Open()
$sql = $con.CreateCommand()
$sql.CommandText = "SELECT Timestamp,Watts from History order by Timestamp desc limit $NumberArray"
$adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $sql
$data = New-Object System.Data.DataSet
[void]$adapter.Fill($data)
$array_owl=$data.tables.rows


$uri="${InfluxDBURL}:$InfluxDBPort/write?precision=s&db=$InfluxDBDB"

$i=0
foreach ($Row in $array_owl)
{ 
  $Timestamp=$data.tables.rows[$i] | foreach { $_.Timestamp }
  $Watts=$data.tables.rows[$i] | foreach { $_.Watts }

    $postParams="owl_grafana,location=home watts=$Watts $Timestamp"
    Invoke-RestMethod -Uri $uri -Method POST -Body $postParams -Credential $cred
    $i++
}