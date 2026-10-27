# 显示拓扑看门狗：监测"显示器数量/虚拟显示适配器"变化，定位呼吸式黑屏元凶
# 用法：以任意用户运行本脚本，它会每 3 秒记录一次；发现变化时写带时间戳的事件到日志。
# 黑屏发生后，用记事本打开日志，找黑屏时间点附近是否有 "CHANGE" 行。
$log = Join-Path $env:TEMP "display_watchdog.log"
"[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] WATCHDOG START (Ctrl+C 退出)" | Out-File -FilePath $log -Encoding utf8 -Append

$prevCount = -1
$prevVirt  = $null
$prevList  = ""

while ($true) {
    $dm  = Get-CimInstance Win32_DesktopMonitor -ErrorAction SilentlyContinue
    $vc  = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
    $virt = ($vc | Where-Object { $_.Name -match "Virtual" } | Select-Object -ExpandProperty Name) -join ","
    $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    $curList = ($dm | ForEach-Object { "$($_.DeviceID):$($_.Caption):$($_.Status)" }) -join " | "
    $changed = $false
    $reason  = ""

    if ($dm.Count -ne $prevCount) { $changed = $true; $reason += " 监视器数 $prevCount->$($dm.Count)" }
    if ($virt -ne $prevVirt)      { $changed = $true; $reason += " 虚拟显示[$prevVirt]->[$virt]" }
    if ($curList -ne $prevList)   { $changed = $true; $reason += " 拓扑变化" }

    if ($changed) {
        $line = "[$now] CHANGE$reason`n        当前监视器: $curList`n        虚拟显示适配器: $virt"
        $line | Out-File -FilePath $log -Encoding utf8 -Append
        Write-Host $line
    }
    $prevCount = $dm.Count; $prevVirt = $virt; $prevList = $curList
    Start-Sleep -Seconds 3
}
