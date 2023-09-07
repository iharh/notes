@echo off
setlocal
set F_HDR=-o "-----" -n -f -n -o "-----" -n
set B_SEP=-b -b
set C_TOTAL=-m "IndexingReport/Status/Total"         -i "@failureCount != 0" -o "totalFailureCount: "   -v "@failureCount" -n
set C_ADDED=-m "IndexingReport/Status/DocsAdded"     -i "@failureCount != 0" -o "addedFailureCount: "   -v "@failureCount" -n
set C_UPDATED=-m "IndexingReport/Status/DocsUpdated" -i "@failureCount != 0" -o "updatedFailureCount: " -v "@failureCount" -n
set C_DELETED=-m "IndexingReport/Status/DocsDeleted" -i "@failureCount != 0" -o "deletedFailureCount: " -v "@failureCount" -n
xml sel -t %C_TOTAL% %B_SEP% %C_ADDED% %B_SEP% %C_UPDATED% %B_SEP% %C_DELETED% *.xml
endlocal
