FS = require 'fs'
IRC = require 'irc'
ZMQ = require 'zmq'

irc2zmq = ZMQ.socket 'pub'
irc2zmq.connect 'ipc://irc2zmq.sock'

zmq2irc = ZMQ.socket 'sub'
zmq2irc.bindSync 'ipc://zmq2irc.sock'

config = JSON.parse(FS.readFileSync 'config.json').irc

zmq2irc.subscribe ''
zmq2irc.on 'message', (rawMsg) ->
    msg = JSON.parse rawMsg
    console.log msg
    switch msg.command
        when "say"
            ircClient.say msg.to, msg.message
        else
            console.log "Unknown ZMQ message: ", msg

console.log "Creating IRC client"
ircClient = new IRC.Client(config.server, config.nickname,
    autoConnect: false,
    stripColors: true,
    floodProtection: true,
    channels: config.channels,
)
ircClient.addListener 'error', (e) ->
    console.log 'IRC error: ', e

ircClient.addListener 'raw', (rawMsg) ->
    console.log('raw: ', rawMsg)

ircClient.addListener 'message', (from, to, msg) ->
    zmqObj =
        command: "say",
        from: from,
        to: to
        message: msg
    irc2zmq.send(JSON.stringify(zmqObj))

ircClient.connect 10, () ->
    console.log "Connected."
