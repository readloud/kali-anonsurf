import .. / modules / [torPorts, encoder]
import strutils
import .. / .. / utils / services

type
  Status* = ref object
    isAnonSurfService*: int
    isTorService*: int
    isAnonSurfBoot*: bool
  PortStatus* = object
    isReadError*: bool
    isControlPort*: bool
    isDNSPort*: bool
    isSocksPort*: bool
    isTransPort*: bool

const surfVersion* = "3.1.8"


proc getSurfStatus*(): Status =
  #[
    Get status of services (activated / inactivated)
    TODO use libdbus https://nimble.directory/pkg/dbus
  ]#
  let
    surfStatus = getServStatus("anonsurfd")
    torStatus = getServStatus("tor")
    surfEnable = isServEnabled("anonsurfd.service")

  var
    finalStatus: Status
  
  finalStatus = Status(
    isAnonSurfService: surfStatus,
    isTorService: torStatus,
    isAnonSurfBoot: surfEnable,
  )

  return finalStatus


proc getStatusPorts*(): PortStatus =
  #[
    Get current status of all tor Ports
    1. Get ports from torrc. We call function here
      just in case Torrc is changed or tor is restarted
  ]#
  let
    openedAddr = toNixHex(getTorrcPorts())

  result.isReadError = openedAddr.fileErr

  if not openedAddr.fileErr:
    const
      tcpPath = "/proc/net/tcp"
      udpPath = "/proc/net/udp"
    let
      netstat = readFile(tcpPath)
    result.isControlPort = netstat.contains(openedAddr.controlPort)
    result.isSocksPort = netstat.contains(openedAddr.socksPort)
    result.isTransPort = netstat.contains(openedAddr.transPort)
    result.isDNSPort = readFile(udpPath).contains(openedAddr.dnsPort)
