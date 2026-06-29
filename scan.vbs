Sub EmbeddedDCPortScan()
    Dim strHost As String
    Dim ports As Variant
    Dim outputFile As String
    Dim fso As Object, ts As Object
    Dim port As Variant
    Dim result As String
    
    strHost = "your-dc-hostname-or-ip"          ' ← CHANGE THIS
    outputFile = "C:\Users\jmigalh\Desktop\scan.txt"
    
    ports = Array(53, 88, 135, 139, 389, 445, 464, 636, 3268, 3269, 3389)
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set ts = fso.CreateTextFile(outputFile, True)
    
    ts.WriteLine "Port Scan Results for host: " & strHost
    ts.WriteLine "Scan started: " & Now()
    ts.WriteLine String(50, "-")
    
    For Each port In ports
        If IsPortOpen(strHost, CLng(port)) Then
            ts.WriteLine "Port " & port & ": OPEN"
        Else
            ts.WriteLine "Port " & port & ": CLOSED or filtered"
        End If
    Next
    
    ts.WriteLine String(50, "-")
    ts.WriteLine "Scan completed: " & Now()
    ts.Close
    
    MsgBox "Scan completed!" & vbCrLf & "Results saved to Desktop\scan.txt", vbInformation
End Sub

Private Function IsPortOpen(host As String, port As Long) As Boolean
    Dim sock As Object
    On Error Resume Next
    Set sock = CreateObject("MSWinsock.Winsock")
    sock.RemoteHost = host
    sock.RemotePort = port
    sock.Connect
    Application.Wait Now + TimeValue("0:00:01")   ' Wait ~1 second
    IsPortOpen = (sock.State = 7)
    sock.Close
    Set sock = Nothing
    On Error GoTo 0
End Function
