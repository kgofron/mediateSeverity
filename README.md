# mediateSeverity
Check Severity of PVs

## ./check_pv_severity.sh -h

```
Usage: ./check_pv_severity.sh [OPTIONS]
Options:
  -f FILE    Use specified file containing PV names (default: mediaSeverity.STATUSEXT)
  -d         Dynamically discover STATUSEXT PVs from EPICS applications
  -h         Show this help message
```

## On dassrv1 or daq1

* Check path
	* /home/controls/bl11a/applications
* BL=BL11A ./check_pv_severity.sh -d
* ./check_pv_severity.sh -d