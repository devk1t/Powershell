
# get the uptime and model of machines that are reachable.
 # get use

cls
$Result=$null
$Result = @()
$count = @{}
$names = @{}
$NewObject02=$null
$NewObject02=@()
$vaule = 0


# for each hostname provided
#Get-Content C:\build\ntd.txt | ForEach-Object {
Import-CSV c:\build\systems5.csv -Header Type,Hostname,Location,Deployed,WorkCentre,WcName | Foreach-Object {

    $hostName = $_.Hostname
    $workcentre = $_.WorkCentre
    $location = $_.Location
    $type = $_.Type

    if (Test-Connection $hostName){

        Write-Host -Debug 'System ' $hostName '_____________________________________________________________'

        # get the current system up-time
        $os = Get-WmiObject win32_operatingsystem -ComputerName $hostName
        $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))    

        # retrive logs for given number of days
        # Write-Host -Debug 'Processesing logins for system '$hostName', retreiving logs.'
        $logs = Get-EventLog System -Source Microsoft-Windows-WinLogon -After (Get-Date).AddDays(-14) -ComputerName $hostName
     
        # sort the logs
        # Write-Host -Debug 'Sorting logs for ' $hostName
        If ($logs) { 
        
            ForEach ($log in $logs) { 
                If ($log.InstanceId -eq 7001) { 
                       #get user
                       $event_user_name = (New-Object System.Security.Principal.SecurityIdentifier $log.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])

                       #check for user
                       if (-not $names.ContainsKey($event_user_name)){
                            #$names.$event_user_name = $event_user_name
                            $date = Get-Date
                            $current_logon_time = (New-TimeSpan -Start $log.TimeWritten -End $date).Days
                            $names.$event_user_name = [ordered] @{  
                                'location' = $location;
                                'hostname' = $hostName;
                                'type' = $type;
                                'workcentre' = $workcentre;                 
                                'name' = $event_user_name;
                                'count' = 1; 
                                'date' = $log.TimeWritten;
                                'uptime' = [int]$uptime.TotalDays
                                'current' = $current_logon_time;
                            }

                       } else {
                            $names.$event_user_name.count += 1;
                       }
  
                   }
                ElseIf ($log.InstanceId -eq 7002) { 
                    if (-not $names.ContainsKey($event_user_name)){
                            #$names.$event_user_name = $event_user_name
                            $names.$event_user_name = [ordered] @{  
                                'location' = $location;
                                'hostname' = $hostName;
                                'type' = $type;
                                'workcentre' = $workcentre;                 
                                'name' = $event_user_name;
                                'count' = 1; 
                                'date' = $log.TimeWritten;
                                'uptime' = $uptime.TotalHours
                                'current' = $current_logon_time;
                            }

                       } else {
                        
                       }
                }
                Else { 
                    Continue
                }
         }

        foreach ($system in $names.Keys) {

             $result += New-Object PSObject -Property @{
                Location = $names.${system}.location
                Cost_Centre = $names.${system}.workcentre
                Computer = $names.${system}.hostname
                Type = $names.${system}.type
                User = $names.${system}.name
                Loggin_Count = $names.${system}.count
                Last_Loggin_Date = $names.${system}.date
                Current_Logged_in_Days = $names.${system}.current
                System_Boot_Time_Days = $names.${system}.uptime
            }
        
        }
        $result | Select Location, Cost_Centre, Computer, Type, User, Loggin_Count, Last_Loggin_Date, Current_Logged_in_Days, System_Boot_Time_Days
       }

  } else{
    Write-Host -Debug $hostName ' is unreachable or not powered on.'
  }
}


$result | Select-Object 'Location', 'Cost_Centre', 'Computer', 'Type', 'User', 'Loggin_Count', 'Last_Loggin_Date', 'Current_Logged_in_Days', 'System_Boot_Time_Days' | Export-Csv -Path C:\build\rye.csv -NoTypeInformation
Write-Host "Done."

