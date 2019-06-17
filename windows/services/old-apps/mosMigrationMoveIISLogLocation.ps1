Import-Module WebAdministration
$serviceAccountUsername = "HPS\zhps_MOSPRODAdmin";
$serviceAccountPassword = "";
$paths = @{
	'logFiles' = "D:\iislogs";
	'scripts' = "D:\scripts";
	'webRoot' = "D:\wwwroot"
}
foreach($path in $paths.GetEnumerator()) {
	if(!(Test-Path -Path $path.Value)) {
		mkdir $path.Value;
	}
}

$webApplicationTypes = @{
'POS' = "v2.0";
'Mosaic' = "v4.0"
};
$applicationPoolNames = @(
'One',
'Two',
'Three',
'Four'
);
$siteName = 'Default Web Site';
foreach($webApplicationType in $webApplicationTypes.GetEnumerator()) {
	foreach($applicationPoolName in $applicationPoolNames) {
		$appPool = $null;
		if(Test-Path "IIS:\AppPools\$($($webApplicationType.Name) + $applicationPoolName)") {
			$appPool = Get-Item IIS:\AppPools\$(($webApplicationType.Name) + $applicationPoolName);
		}
		if($appPool -eq $null) {
			$appPool = New-Item IIS:\AppPools\$(($webApplicationType.Name) + $applicationPoolName);
		}
		$appPool.processModel.idleTimeout=[TimeSpan]0;
		$appPool.startMode="AlwaysRunning";
		$appPool | Set-Item;
		$appPool | Set-ItemProperty -Name "processModel" -Value @{userName=$serviceAccountUsername;password=$serviceAccountPassword;identityType=3};
		$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value ($webApplicationType.Value);
	}
}
$site = Get-Item  'IIS:\Sites\Default Web Site';
$site.logFile.directory = $paths.Item('logFiles');
$site | Set-Item;
$site | Set-ItemProperty -Name "physicalPath" -Value $($paths.Item('webRoot'));
$webrootfolders = Get-ChildItem $paths.Item('webRoot');
foreach($webrootfolder in $webrootfolders) {
	ConvertTo-WebApplication "IIS:\Sites\$siteName\$webrootfolder"
}