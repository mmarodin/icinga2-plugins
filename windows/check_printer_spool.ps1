# Check printer spool status script for Icinga2
# Require: Powershell script execution enabled
# v.20200811 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

#Get-Printer -ComputerName HOST7 | where PrinterStatus -eq Error | fl Name,JobCount
$Printers_Array = Get-Printer -ComputerName $env:COMPUTERNAME | Select Name, JobCount, PrinterStatus
ForEach($Printer in $Printers_Array) {
  If ($($Printer.PrinterStatus -Like "*Error*")) {
    If ($OUT_ERROR) {
      $OUT_ERROR = $OUT_ERROR + ", "
    }
    $OUT_ERROR = $OUT_ERROR+ $($Printer.Name) + " (" + $($Printer.JobCount) + ")"
  }
  If ($($Printer.PrinterStatus -Eq "Offline")) {
    If ($OUT_OFFLINE) {
      $OUT_OFFLINE = $OUT_OFFLINE + ", "
    }
    $OUT_OFFLINE = $OUT_OFFLINE+ $($Printer.Name) + " (" + $($Printer.JobCount) + ")"
  }
  If ($($Printer.PrinterStatus -Eq "TonerLow")) {
    If ($OUT_TONER) {
      $OUT_TONER = $OUT_TONER + ", "
    }
    $OUT_TONER = $OUT_TONER+ $($Printer.Name) + " (" + $($Printer.JobCount) + ")"
  }
  $PERFDATA = $PERFDATA + " '" + $($Printer.Name) + "'=" + $($Printer.JobCount)
}

If ($OUT_ERROR) {
  $TEXT = "in Error state (jobs queued): $OUT_ERROR"
  $EXIT = 2
} ElseIf ($OUT_OFFLINE) {
  $TEXT = "in Offline state (jobs queued): $OUT_OFFLINE"
  $EXIT = 1
} ElseIf ($OUT_TONER) {
  $TEXT = "in TonerLow state (jobs queued): $OUT_TONER"
  $EXIT = 0
} Else {
  $TEXT = "OK"
  $EXIT = 0
}

Write-Host "Printers $TEXT |$PERFDATA"
$host.SetShouldExit($EXIT)
