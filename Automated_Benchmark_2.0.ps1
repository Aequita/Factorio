#
#
#
# >>>>>>>>> If you have/want other folder-setting, change these <<<<<<<<<
#
# Test-settings
$testpath = "C:\Temp\Factorio\Test-Maps\"
$outputpath = "C:\Temp\Factorio\"
# Game-related paths
$game = "C:\Program Files (x86)\Steam\steamapps\common\Factorio\bin\x64\factorio.exe"
$savepath = "$env:APPDATA\Factorio\saves\"
#
# >>>>>>>>> If you have/want other folder-setting, change these <<<<<<<<<
#
#
#
# Info about the benchmark
write-host '----------------------------------------------------'
write-host "About this benchmark:"
write-host "You'll be prompted to input # of runs and ticks"
write-host "as well as the desired sub-folder below $testpath to test recursively."
write-host "If no folder is specified, all saves below \Test-Maps\ will be tested recursively."
write-host '----------------------------------------------------'
write-host "When the save-files exist in the original game-savepath"
write-host "$savepath those are tested."
write-host "If not, the copies in \Test-Maps\ are used."
write-host "This is indicated by [Save-File] or [Test-File] during the benchmark."
write-host '----------------------------------------------------'
write-host "Hit [ENTER] three times to test all saves with default values."
write-host '----------------------------------------------------'
#
# Define arrays
$sub = @()
$files = @()
$onerun_times = @()
$export = @()
#
# Check if Test-directory exists
if(!(Test-Path $testpath)){
	New-Item -ItemType Directory -Path $testpath -Force | Out-null
	write-host
	write-host
	write-host $testpath
	write-host 'Directory created - populate it with save-files and continue benchmark'
	write-host
	pause
}
#
# Pre-check if .zips exist
$t_files = Get-ChildItem $testpath$s -Recurse | Where {$_.extension -like ".zip"}
while($t_files.count -eq 0){
	write-host
	write-host
	write-warning "No save-files available. Add files or exit benchmark."
	write-host
	pause
	$t_files = Get-ChildItem $testpath$s -Recurse | Where {$_.extension -like ".zip"}
}
#
write-host
write-host
#
# Prompt input of sub-folder to test
while($files.count -eq 0){
	$sub = Read-Host -Prompt 'Input sub-folder to test
	* empty = test all
	* separate by "," to list multiple
	* can be longer\sub\folder\paths
'
	write-host
	#
	$sub = $sub.Split(",")
	foreach ($s in $sub){
		if(test-path $testpath$s){
			$files += Get-ChildItem $testpath$s -Recurse | Where {$_.extension -like ".zip"}
		}
		else{
			write-warning "Folder \$s\ not found. Check spelling or sub\folder\path"
			write-host
			$files = $null
			$files = @()
			break
		}
	}
}
#
# Prompt input of runs to test
while($runs -notmatch "^\d+$"){
	$runs = Read-Host -Prompt 'Input number of runs to test (empty = 5)'
	if(!$runs){
		$runs = 5
	}
	write-host
}
#
# Prompt input of ticks to test
while($ticks -notmatch "^\d+$"){
	$ticks = Read-Host -Prompt 'Input number of ticks to test (empty = 1000)'
	if(!$ticks){
		$ticks = 1000
	}
	write-host
}
#
# Benchmark available .zips
for($f=0; $f -le ($files.count-1); $f++){
	#
	$onerun_times = $null
	$onerun_times = @()
	#
	# Check if file is available in game-savepath
	write-host
	$savefile = $savepath + $files[$f]
	if (test-path $savefile){
		write-host "Testing [Save-File]" $files[$f] $runs "times ..."
	}
	else{
		$savefile = $files[$f].fullname
		write-host "Testing [Test-File]" $files[$f] $runs "times ..."
	}
	write-host '----------------------------------------------------'
	#
	# Out sub-folder
	$folder_out = $files[$f].fullname -replace [regex]::Escape($testpath) -replace [regex]::Escape($files[$f])
	#	
	for ($r=1; $r -le $runs; $r++){
		#
		$log = & $game --benchmark $savefile --benchmark-ticks $ticks --disable-audio | Out-String -stream
		#
		# Out files tested
		$files_out = $files[$f]
		foreach($l in $log){
			if("$l" -like "*; Factorio*"){
				$t_info = $null
				$t_info = @()
				$t_info = $l.substring(9)  -replace ";" -replace " \(.*" -replace " Factorio"
				$t_info = $t_info.split(" ")
				$date_out = $t_info[0]
				$time_out = $t_info[1]
				$version_out = $t_info[2]
				}
			elseif("$l" -like "*Performed*"){
				# Out nr. of ticks tested
				$ticks_out = $l -replace ".*Performed " -replace " updates.*"
			}
			elseif("$l" -like "*avg:*"){
				# Out relevant times
				write-host $l
				$avg_out = $l -replace ".*avg: " -replace " ms.*"
				$min_out = $l -replace ".*min: " -replace " ms.*"
				$max_out = $l -replace ".*max: " -replace " ms.*"
			}
			elseif("$l" -like "*error*"){
				# Out errors
				write-host $l
				write-host
				write-warning 'Error - canceling benchmark ...'
				write-host
				pause
				exit
			}
		}
		# Collect properties in temp
		$temp = new-object pscustomobject -property @{
			Date = "$date_out"
			Time = "$time_out"
			Version = "$version_out"
			Subfolder = "$folder_out"
			Test = "$files_out"
			Ticks = "$ticks_out"
			Avg = "$avg_out"
			Min = "$min_out"
			Max = "$max_out"
		}
		$onerun_times += $temp
		#
	}
	#
	# Evaluate average times (times/runs)
	$t_date = $onerun_times."Date"[0]
	$t_time = $onerun_times."Time"[0]
	$t_version = $onerun_times."Version"[0]
	$t_folder =$onerun_times."Subfolder"[0]
	$t_test = $onerun_times."Test"[0]
	$t_ticks = $onerun_times."Ticks"[0]
	$t_avg = $onerun_times | Measure-Object -Property  Avg -Average | Select-Object -expand Average
	$t_avg = [math]::Round($t_avg,3)
	$t_min = $onerun_times | Measure-Object -Property Min -Average | Select-Object -expand Average
	$t_min = [math]::Round($t_min,3)
	$t_max = $onerun_times | Measure-Object -Property Max -Average | Select-Object -expand Average
	$t_max = [math]::Round($t_max,3)
	$temp = new-object pscustomobject -property @{
		Date = "$t_date"
		Time = "$t_time"
		Version = "$t_version"
		Subfolder = "$t_folder"
		Test = "$t_test"
		Ticks = "$runs x $t_ticks"
		Avg = "$t_avg" + ' ms'
		Min = "$t_min" + ' ms'
		Max = "$t_max" + ' ms'
	}
	#
	$export += $temp
	#
	write-host '----------------------------------------------------'
	write-host '= avg:' $t_avg 'ms, min:' $t_min 'ms, max:' $t_max 'ms'
	write-host
}
#
$bench_csv = $outputpath + 'Benchmark.csv'
#
# Check if Benchmark.csv can be accessed
while($ok -ne $true){
	Try{
		$ok = $true
		[io.file]::OpenWrite($bench_csv).close()
	}
	Catch{
		$ok = $false
		write-host
		Write-Warning "Output-file Benchmark.csv is in use."
		write-host "Close to write results."
		write-host
		pause
	}
}
#
# Sort, export to .csv and remove quotes
$export = $export | select-object Date,Time,Version,Subfolder,Test,Ticks,Avg,Min,Max,Comment
$export | export-csv -path $bench_csv -notypeinformation -append -Delimiter ';'
# (Get-Content $bench_csv) | % {$_ -replace '"', ""} | out-file -FilePath $bench_csv -Force -Encoding ascii
#
write-host
write-host
write-host '--------------------- FINISHED ---------------------'
write-host 'Results added to Benchmark.csv in' "$outputpath"
write-host
#
pause
exit
