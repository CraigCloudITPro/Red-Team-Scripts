<#
.Synopsis
   Performs full TCP Connection and UDP port scan.
.DESCRIPTION
   Performs full TCP Connection and UDP port scan against a given host 
   or range of IPv4 addresses.
.EXAMPLE
   Perform TCP Scan of known ports against a host
   
    PS C:\> Invoke-PortScan -Target 172.20.10.3 -Ports 22,135,139,445 -Type TCP

    Host                                                 Port State                        Type                        
    ----                                                 ---- -----                        ----                        
    172.20.10.3                                           135 Open                         TCP                         
    172.20.10.3                                           139 Open                         TCP                         
    172.20.10.3                                           445 Open                         TCP                         

#>
function Invoke-PortScan
{
    [CmdletBinding()]
   
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ParameterSetName = "SingleIP",
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias("IPAddress,Host")]
        [string]$Target,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "Range",
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Range,

        [Parameter(Mandatory=$true,
                   ParameterSetName = "CIDR",
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$CIDR,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=1)]
        [int32[]]$Ports,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false,
                   Position=2)]
        [ValidateSet("TCP", "UDP")]
        [String[]]$Type,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=3)]
        [ValidateSet("TCP", "UDP")]
        [int32]$Timeout=100


    )

    Begin
    {
        # Expand the needed address ranges
        if ($Range)
        {
            $rangeips = $Range.Split("-")
            $targets = New-IPv4Range -StartIP $rangeips[0] -EndIP $rangeips[1]
        }

        # Expnd CIDR
        if ($CIDR)
        {
            $targets = New-IPv4RangeFromCIDR -Network $CIDR
        }

        # Manage single target
        if ($Target)
        {
            $targets = @($Target)
        }
        
        # Set the default ports

    }
    Process
    {
        foreach ($t in $Type)
        {
            if ($t -eq "TCP")
            {
                foreach ($ip in $targets)
                {
                    foreach($p in $Ports)
                    {
                        try
                        {
                            $TcpSocket = new-object System.Net.Sockets.TcpClient
                            #$TcpSocket.client.ReceiveTimeout = $Timeout
                            # Connect to target host and port
                            $TcpSocket.Connect($ip, $p)
                            $ScanPortProps = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                            $ScanPortProps.Add("Host",$ip)
                            $ScanPortProps.Add("Port",$p)
                            $ScanPortProps.Add("State","Open")
                            $ScanPortProps.Add("Type","TCP")
                            $scanport = New-Object psobject -Property $ScanPortProps

                            # Close Connection
                            $tcpsocket.Close()
                            $scanport
                        }
                        catch
                        { 
                            Write-Verbose "Port $p is closed"
                        }
                    }
                }
            }
            elseif ($t -eq "UDP")
            {
                foreach ($ip in $targets)
                {
                    foreach($p in $Ports)
                    {
                   
                        $UDPSocket = new-object System.Net.Sockets.UdpClient
                        $UDPSocket.client.ReceiveTimeout = $Timeout
                        $UDPSocket.Connect($ip,$p)

                        $data = New-Object System.Text.ASCIIEncoding
                        $byte = $data.GetBytes("$(Get-Date)")

                        #Send the data to the endpoint
                        [void] $UDPSocket.Send($byte,$byte.length)

                        #Create a listener to listen for response
                        $Endpoint = New-Object System.Net.IPEndPoint([system.net.ipaddress]::Any,0)

                        try 
                        {
                            #Attempt to receive a response indicating the port was open
                            $receivebytes = $UDPSocket.Receive([ref] $Endpoint)
                            [string] $returndata = $data.GetString($receivebytes)
                            $ScanPortProps = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                            $ScanPortProps.Add("Host",$ip)
                            $ScanPortProps.Add("Port",$p)
                            $ScanPortProps.Add("State","Open")
                            $ScanPortProps.Add("Type","UDP")
                            $scanport = New-Object psobject -Property $ScanPortProps
                            $scanport
                        }
            
                        catch 
                        {
                            #Timeout or connection refused
                            Write-Verbose "Port $p is closed"
                        }

                        finally 
                        {
                            #Cleanup
                            $UDPSocket.Close()
                        }
  
                    }
                }
            }
        }
    }
    End
    {
    }
}
