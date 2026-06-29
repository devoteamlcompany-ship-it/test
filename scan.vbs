Dim strHost
Dim ports
Dim outputFile
Dim fso, ts

' ================== CONFIGURE HERE ==================
strHost = "your-dc-hostname-or-ip"   ' ← CHANGE THIS
' ====================================================

' Common Domain Controller ports + RDP (3389)
ports = Array(53, 88, 135, 139, 389, 445, 464, 636, 3268, 3269, 3389)

outputFile = "C:\Users\jmigalh\Desktop\scan.txt"

Set fso = CreateObject("Scripting.FileSystemObject")
Set ts = fso.CreateTextFile(outputFile, True)

ts.WriteLine "Port Scan Results for host: " & strHost
ts.WriteLine "Scan started: " & Now()
ts.WriteLine String(50, "-")

Dim port
For Each port In ports
    If IsPortOpen(strHost, port) Then
        ts.WriteLine "Port " & port & ": OPEN"
    Else
        ts.WriteLine "Port " & port & ": CLOSED or filtered"
    End If
Next

ts.WriteLine String(50, "-")
ts.WriteLine "Scan completed: " & Now()
ts.Close

Set ts = Nothing
Set fso = Nothing

WScript.Echo "Scan finished! Results saved to:" & vbCrLf & outputFile

' ====================== FUNCTION ======================
Function IsPortOpen(host, port)
    Dim sock, state
    On Error Resume Next
    Set sock = CreateObject("MSWinsock.Winsock")
    sock.RemoteHost = host
    sock.RemotePort = port
    sock.Connect
    
    WScript.Sleep 800   ' Give it time to connect
    
    state = sock.State
    sock.Close
    Set sock = Nothing
    On Error GoTo 0
    
    IsPortOpen = (state = 7)   ' 7 = Connected
End Function
