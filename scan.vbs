Sub PortScanDC()
    Dim target As String
    Dim ports As Variant
    Dim psCommand As String
    Dim outputFile As String
    Dim shell As Object
    Dim fso As Object
    Dim txt As String
    
    ' Define common DC ports + RDP (TCP)
    ports = Array(53, 88, 135, 139, 389, 445, 464, 3268, 3269, 3389)
    
    ' Get target from user
    target = InputBox("Enter target IP or hostname for port scan:", "DC Port Scanner", "192.168.1.1")
    If Trim(target) = "" Then Exit Sub
    
    outputFile = "C:\Users\jmigalh\Desktop\scan.txt"
    
    ' Build PowerShell command for reliable, fast port checks
    ' Uses .NET TcpClient with short timeout for precision (no long waits)
    psCommand = "powershell -NoProfile -ExecutionPolicy Bypass -Command " & _
                """$target = '" & target & "'; " & _
                "$ports = @(" & Join(ports, ",") & "); " & _
                "$results = @(); " & _
                "foreach($port in $ports) { " & _
                "  try { " & _
                "    $tcp = New-Object System.Net.Sockets.TcpClient; " & _
                "    $connect = $tcp.BeginConnect($target, $port, $null, $null); " & _
                "    $success = $connect.AsyncWaitHandle.WaitOne(1500, $false); " & _  ' 1.5s timeout
                "    if($success) { " & _
                "      $tcp.EndConnect($connect); " & _
                "      $results += ""$target`:$port - OPEN""; " & _
                "    } else { " & _
                "      $results += ""$target`:$port - CLOSED""; " & _
                "    } " & _
                "  } catch { " & _
                "    $results += ""$target`:$port - ERROR""; " & _
                "  } finally { " & _
                "    if($tcp) { $tcp.Close() } " & _
                "  } " & _
                "}; " & _
                "$results | Out-File '" & outputFile & "' -Encoding UTF8 -Force; " & _
                "Write-Output 'Scan completed. Results saved to " & outputFile & "'"""
    
    ' Run PowerShell silently
    Set shell = CreateObject("WScript.Shell")
    shell.Run psCommand, 0, True  ' Wait for completion
    
    ' Confirm and optionally show results
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(outputFile) Then
        txt = fso.OpenTextFile(outputFile).ReadAll
        MsgBox "Scan completed!" & vbCrLf & vbCrLf & _
               "Results saved to:" & vbCrLf & outputFile & vbCrLf & vbCrLf & _
               "Preview:" & vbCrLf & Left(txt, 800), vbInformation, "Port Scan Complete"
    Else
        MsgBox "Scan failed to write output file.", vbCritical
    End If
End Sub
