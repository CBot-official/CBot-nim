import
  irc,
  ansi

import
  os,
  nativesockets,
  times,
  random,
  strutils,
  strformat

randomize()

const helpText = [
  fmt"{clrOrange}Commands:",
  fmt"{clrRed}!rainbow {clrDefault}(Rainbow colorize text)",
  fmt"{clrRed}!coin {clrDefault}(Coin toss)",
  fmt"{clrRed}!rr {clrDefault}(Russian Roulette)",
  fmt"{clrRed}!roll {clrDefault}(Dice roll)",
  fmt"{clrRed}!fuckoff {clrDefault}(Leaves the channel)"
].join(" ")

var authPass: string

type
  FormattedResponse = string
  Commands = enum
    cmdNone,
    cmdHelp,
    cmdRainbow,
    cmdCoin,
    cmdRussianRoulette,
    cmdDiceRoll

proc headsOrTails(): string
proc russianRoulette(): string
proc rollDice(sides: int = 6): int

proc rainbowify*(text: string): FormattedResponse
proc handleCommand(client: Irc, e: IrcEvent, message: string, messageFromBot: bool)
proc determineCommand(str: string): Commands
proc handleMsg(client: Irc, e: IrcEvent)

proc handleMsg(client: Irc, e: IrcEvent) =
  let date = format(e.timestamp, "yyyy-MM-dd'T'HH:mm:ss", local())
  echo fmt"{date}: {e.text}"

  # TODO: Had to add this for the irc-nerds network.
  # Why does it not like the first time I try to identify?
  # if e.text == "If you do not change within 1 minute, I will change your nick." and authPass.len > 0:
  #   client.privmsg("NickServ", fmt"IDENTIFY {authPass}")

  if e.cmd == MPrivMsg:
    if e.text.startsWith('!'):
      client.handleCommand(e, e.text, e.text.len != e.text.len)

proc determineCommand(str: string): Commands =
  case str:
    of "help", "commands", "h": cmdHelp
    of "rainbow": cmdRainbow
    of "coin": cmdCoin
    of "rr", "roulette": cmdRussianRoulette
    of "roll", "dice", "die": cmdDiceRoll
    else: return cmdNone

proc handleCommand(client: Irc, e: IrcEvent, message: string, messageFromBot: bool) =
  ## message:
  ##   The message to parse, e.g. !rainbow foobar
  let
    split = message.split()
    commandText = if split[0].len > 1: split[0][1 .. ^1] else: ""
    command = determineCommand(commandText)
    text = if split.len < 2: "" else: split[1..^1].join(" ")

  echo text

  case command:
    of cmdNone:
      discard

    of cmdHelp:
      client.privmsg(e.origin, helpText)

    of cmdRainbow:
      client.privmsg(e.origin, rainbowify(text))

    of cmdCoin:
      client.privmsg(e.origin, fmt"{headsOrTails()}!")

    of cmdRussianRoulette:
      client.privmsg(e.origin, russianRoulette())

    of cmdDiceRoll:
      let sides =
        if split.len > 1:
          try:
            parseInt(split[1])
          except: 6
        else: 6

      let message = fmt"{clrBlue}{e.nick} rolled:{clrOrange} {rollDice(sides)}"
      client.privmsg(e.origin, message)

proc headsOrTails(): string =
  if rand(1) == 0:
    "Heads"
  else:
    "Tails"

proc russianRoulette(): string =
  if rand(1 .. 6) == 6:
    "**BANG!**"
  else:
    "*click*"

proc rollDice(sides: int): int =
  return rand(1 .. max(1, sides))

proc rainbowify*(text: string): FormattedResponse =
  var i = 0
  while i < text.len:
    for color in rainbowColors:
      if i == text.len:
        break
      result.add(fmt"{color}{text[i]}")
      i.inc

when isMainModule:
  let
    port = parseInt(getEnv("IRC_PORT", "6697"))
    client = newIrc(
      "irc.irc-nerds.net",
      port = Port(port),
      useSsl = true,
      nick = getEnv("IRC_NICK", "CBot|Nim"),
      joinChans = @["#cbot"]
    )

  client.connect()

  authPass = getEnv("IRC_PASSWORD", "")
  if authPass.len > 0:
    client.privmsg("NickServ", fmt"IDENTIFY {authPass}")
    # TODO: https://datatracker.ietf.org/doc/html/rfc4422

  while true:
    var e: IrcEvent
    if client.poll(e):
      # echo e.raw
      case e.typ:
      of EvMsg:
        client.handleMsg e
      of EvConnected:
        echo "EvConnected"
        # Connection events
      of EvDisconnected, EvTimeout:
        echo $e.typ
        client.reconnect()

