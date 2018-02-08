$usersxml = [xml] (Get-Content users_2.0.xml)

#$usersxml.cerberus.profiles.user | Export-CSV outputusers.csv -Delimiter '|' -NoTypeInformation


$count = 0;
$disableduserscount = 0;
$disableduserslist = "";

$usersarray = New-Object System.Collections.ArrayList($null)
$usersarray.AddRange(150);

foreach ($user in $usersxml.cerberus.profiles.user){

$container = @{};

   #$count 
   $user.name 
   #$user.isdisabled.value;
   echo "----";
   $user.rootList.ChildNodes.Count;
   $user.rootList.root.name;
   $user.rootList.root.path;
   echo "##########################";

   $container.accountname = $user.name;
   if($user.rootList.ChildNodes.Count -gt 1){
    foreach($root in $user.rootList){
    }
   $container.directory = $user.rootList.root.name;
   }else{
   $container.directory = $user.rootList.root.name;
   }
   
   $container.path = $user.rootList.root.path

   $usersarray.Add((New-Object PSObject -Property $container));
   

   #$usersarray.Add($user.name);
  # $usersarray.Add($user.rootList.root.name);
   #$usersarray.Add($user.rootList.root.path);
   #$usersarray | Out-File -Enc ASCII -Append scriptoutput-test.txt

   $count++;

   if($user.isdisabled.value -eq "true"){ 
    $disableduserscount++;
    $disableduserslist = $disableduserslist + $user.name;
   }
}
echo "______________________";
echo "Total Users: " $count;
echo "Total Disabled Users: " $disableduserscount;
echo "Disabled Users: " $disableduserslist;

#$usersarray | Export-Csv  "FINAL-output-all-users-FTP.csv" -NoTypeInformation -Encoding UTF8 -Delimiter '|'
