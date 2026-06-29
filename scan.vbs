Sub DC_Port_Scanner()

    Dim target As String
    Dim ports As Variant
    Dim timeoutMs As Long
    Dim outputFile As String
    Dim fso As Object, txtFile As Object
    Dim logContent As String
    Dim i As Integer, port As Long
    Dim result As String
    
    ' ============= CONFIGURATION =============
    target = "192.168.1.100"         ' <<< CHANGE THIS to your Domain Controller IP or hostname
    
    ports = Array(53, 88, 135, 139, 389, 445, 464, 636, 3268, 3269, 9389, 3389)
    timeoutMs = 2000                 ' Connection timeout in milliseconds
    outputFile = "C:\Users\X\Desktop\scan.txt"
    ' =========================================
    
    If target = "" Then
        MsgBox "Target IP/Hostname is not configured!", vbCritical
        Exit Sub
    End If
    
    logContent = "============================================" & vbCrLf & _
                 "Domain Controller TCP Port Scanner" & vbCrLf & _
                 "Target: " & target & vbCrLf & _
                 "Scan started: " & Now & vbCrLf & _
                 "============================================" & vbCrLf & vbCrLf
    
    Application.StatusBar = "Scanning " & target & "... Please wait."
    
    For i = LBound(ports) To UBound(ports)
        port = ports(i)
        If IsPortOpen(target, port, timeoutMs) Then
            result = "OPEN"
            logContent = logContent & "[+] Port " & port & " is OPEN" & vbCrLf
        Else
            result = "CLOSED or filtered"
            logContent = logContent & "[-] Port " & port & " is CLOSED or filtered" & vbCrLf
        End If
        
        DoEvents
    Next i
    
    logContent = logContent & vbCrLf & "Scan completed at " & Now
    
    ' Write results to file
    On Error Resume Next
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set txtFile = fso.CreateTextFile(outputFile, True, True)
    txtFile.Write logContent
    txtFile.Close
    On Error GoTo 0
    
    Application.StatusBar = False
    
    MsgBox "Scan finished!" & vbCrLf & vbCrLf & _
           "Target: " & target & vbCrLf & _
           "Results saved to:" & vbCrLf & outputFile, vbInformation, "DC Port Scanner"

End Sub

' =============================================
Function IsPortOpen(host As String, port As Long, timeout As Long) As Boolean
    Dim sock As Object
    Dim startTime As Single
    
    On Error Resume Next
    Set sock = CreateObject("MSWinsock.Winsock.1")
    
    With sock
        .Protocol = 0          ' TCP
        .RemoteHost = host
        .RemotePort = port
        startTime = Timer
        .Connect
    End With
    
    ' Wait for result or timeout
    Do While (sock.State <> 7) And (sock.State <> 9) And ((Timer - startTime) * 1000 < timeout)
        DoEvents
        Application.Wait Now + TimeSerial(0, 0, 0) / 50
    Loop
    
    If sock.State = 7 Then
        IsPortOpen = True
        sock.Close
    Else
        IsPortOpen = False
        sock.Close
    End If
    
    Set sock = Nothing
    On Error GoTo 0
End Function
