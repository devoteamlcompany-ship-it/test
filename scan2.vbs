Option Explicit

' Winsock API Declarations (compatible with 32/64-bit Office)
Private Const AF_INET As Long = 2
Private Const SOCK_STREAM As Long = 1
Private Const IPPROTO_TCP As Long = 6
Private Const SOCKET_ERROR As Long = -1
Private Const INVALID_SOCKET As Long = -1
Private Const WSADESCRIPTION_LEN As Long = 256
Private Const WSASYS_STATUS_LEN As Long = 128
Private Const FIONBIO As Long = &H8004667E   ' For non-blocking (optional timeout handling)

Private Type WSAData
    wVersion As Integer
    wHighVersion As Integer
    szDescription As String * WSADESCRIPTION_LEN
    szSystemStatus As String * WSASYS_STATUS_LEN
    iMaxSockets As Integer
    iMaxUdpDg As Integer
    lpVendorInfo As LongPtr
End Type

Private Type sockaddr_in
    sin_family As Integer
    sin_port As Integer
    sin_addr As Long
    sin_zero As String * 8
End Type

Private Declare PtrSafe Function WSAStartup Lib "ws2_32.dll" (ByVal wVersionRequired As Integer, ByRef lpWSAData As WSAData) As Long
Private Declare PtrSafe Function WSACleanup Lib "ws2_32.dll" () As Long
Private Declare PtrSafe Function socket Lib "ws2_32.dll" (ByVal af As Long, ByVal socktype As Long, ByVal protocol As Long) As LongPtr
Private Declare PtrSafe Function closesocket Lib "ws2_32.dll" (ByVal s As LongPtr) As Long
Private Declare PtrSafe Function connect Lib "ws2_32.dll" (ByVal s As LongPtr, ByRef name As sockaddr_in, ByVal namelen As Long) As Long
Private Declare PtrSafe Function htons Lib "ws2_32.dll" (ByVal hostshort As Long) As Integer
Private Declare PtrSafe Function inet_addr Lib "ws2_32.dll" (ByVal cp As String) As Long
Private Declare PtrSafe Function ioctlsocket Lib "ws2_32.dll" (ByVal s As LongPtr, ByVal cmd As Long, ByRef argp As Long) As Long

' Helper to resolve hostname or IP
Private Declare PtrSafe Function gethostbyname Lib "ws2_32.dll" (ByVal name As String) As LongPtr
Private Declare PtrSafe Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As LongPtr)

Public Sub PortScanDC()
    Dim target As String
    Dim ports As Variant
    Dim results As String
    Dim fso As Object
    Dim filePath As String
    
    ' === CONFIGURE HERE ===
    target = "127.0.0.1"   ' CHANGE TO YOUR TARGET IP or hostname (e.g. "dc01.contoso.local")
    ' Common DC ports + RDP (3389). Add/remove as needed.
    ports = Array(53, 88, 135, 139, 389, 445, 464, 636, 3268, 3269, 3389)
    
    filePath = "C:\Users\jmigalh\Desktop\scan.txt"
    
    results = "Port Scan Results for " & target & " at " & Now & vbCrLf & _
              String(60, "-") & vbCrLf & _
              "PORT     STATUS" & vbCrLf
    
    Dim i As Integer
    For i = LBound(ports) To UBound(ports)
        Dim port As Long
        port = ports(i)
        If IsPortOpen(target, port) Then
            results = results & port & "      OPEN" & vbCrLf
        Else
            results = results & port & "      CLOSED/FILTERED" & vbCrLf
        End If
    Next i
    
    results = results & String(60, "-") & vbCrLf & "Scan complete."
    
    ' Write to file (overwrite)
    Set fso = CreateObject("Scripting.FileSystemObject")
    With fso.CreateTextFile(filePath, True, True)  ' True = overwrite, True = Unicode
        .Write results
    End With
    
    MsgBox "Scan complete! Results saved to:" & vbCrLf & filePath, vbInformation
End Sub

Private Function IsPortOpen(ByVal Host As String, ByVal Port As Long) As Boolean
    Dim wsadata As WSAData
    Dim sock As LongPtr
    Dim addr As sockaddr_in
    Dim res As Long
    Dim timeout As Long
    
    ' Init Winsock
    If WSAStartup(&H202, wsadata) <> 0 Then Exit Function
    
    sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
    If sock = INVALID_SOCKET Then
        WSACleanup
        Exit Function
    End If
    
    ' Optional: Set short timeout (~2-3s) via non-blocking + select-like behavior, but simplified here
    ' For speed/reliability we use blocking connect (Windows default timeout is reasonable for local/DC scans)
    
    With addr
        .sin_family = AF_INET
        .sin_port = htons(Port)
        .sin_addr = inet_addr(Host)
        If .sin_addr = INADDR_NONE Then
            ' Try hostname resolution if not dotted IP
            Dim h As LongPtr
            h = gethostbyname(Host)
            If h <> 0 Then
                CopyMemory .sin_addr, ByVal h + 12, 4  ' Rough offset for h_addr
            End If
        End If
    End With
    
    res = connect(sock, addr, LenB(addr))
    
    IsPortOpen = (res <> SOCKET_ERROR)
    
    closesocket sock
    WSACleanup
End Function

Private Const INADDR_NONE As Long = &HFFFFFFFF
