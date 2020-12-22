# Game-related paths
$game = "C:\Program Files (x86)\Steam\steamapps\common\Factorio\bin\x64\factorio.exe"
# $savepath = "$env:APPDATA\Factorio\saves\"
#
# Test-settings
$testpath = "C:\Temp\Factorio\Test-Maps\"
$outputpath = "C:\Temp\Factorio\"
#
# Check directories
$dircreate = $false
if(!(Test-Path $testpath)){
	New-Item -ItemType Directory -Force -Path $testpath
	$dircreate = $true
}
if($dircreate){
	cls
	write-host $testpath
	write-host 'Directory created - populate it with save-files and restart test'
	write-host 'Test will exit'
	write-host
	pause
	exit
}
#
# Read all .zip-files
$files = Get-ChildItem $testpath | Where {$_.extension -like ".zip"}
if($files.count -eq 0){
	write-host 'No files to test in' $testpath
	write-host 'Test will exit'
	write-host
	pause
	exit
}
#
# Request input of ticks to test
while ($ticks -notmatch "^\d+$"){
	write-host
	$ticks = Read-Host -Prompt 'Input number of ticks to test'
	write-host
	write-host
}
#
# Benchmark available .zips
$export = @()
foreach ($f in $files){
	#
	# Execute benchmark
	write-host "Testing" $f
	$log = & $game --benchmark $testpath$f --benchmark-ticks $ticks --disable-audio | Out-String -stream
	#
	# Analyze return-log and collect *_out for .csv
	#
	# Out files tested
	$files_out = "$f"
	foreach ($l in $log) {
		 if("$l" -like "*Performed*"){
			# Out nr. of ticks tested
			write-host $l
			$ticks_out = $l -replace ".*Performed " -replace " updates.*"
		 }
		 elseif("$l" -like "*avg:*"){
			# Out relevant times
			write-host $l
			$avg_out = $l -replace ".*avg: " -replace ", min:.*"
			$min_out = $l -replace ".*min: " -replace ", max:.*"
			$max_out = $l -replace ".*max: "
		 }
		 elseif("$l" -like "*error*"){
			 # Out errors
			 write-host $l
			 write-host
			 write-host 'Error - Test canceled'
			 write-host
			 pause
			 exit
		 }
	}
	# Collect properties in temp
	$temp = new-object pscustomobject -property @{
		 Max= "$max_out"
		 Min = "$min_out"
		 Avg = "$avg_out"
		 Ticks = "$ticks_out"
		 Test = "$files_out"
	}
	$export += $temp
#
# Extra lines for readability
write-host
write-host
}
#
# Sort, export to .csv and remove quotes
write-host
write-host '--------------------- FINISHED ---------------------'
write-host 'Results saved to Benchmark.csv in' "$outputpath"
write-host
$export = $export | select-object Test,Ticks,Avg,Min,Max
$export | export-csv -path ($outputpath + 'Benchmark.csv') -notypeinformation
(Get-Content ($outputpath + 'Benchmark.csv')) | % {$_ -replace '"', ""} | out-file -FilePath ($outputpath + 'Benchmark.csv') -Force -Encoding ascii

#
pause
exit