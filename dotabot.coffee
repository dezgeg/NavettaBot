FS = require 'fs'
ZMQ = require 'zmq'
Util = require 'util'
Steam = require 'steam'
Dota2 = require 'dota2'

irc2zmq = ZMQ.socket 'sub'
irc2zmq.bindSync 'ipc://irc2zmq.sock'

zmq2irc = ZMQ.socket 'pub'
zmq2irc.connect 'ipc://zmq2irc.sock'

config = JSON.parse(FS.readFileSync 'config.json').dota

steamClient = new Steam.SteamClient()
dotaClient = new Dota2.Dota2Client(steamClient, true)

steamClient.on 'error', (e) ->
    console.log 'Steam error: ', e

# for debugging
steamClient.on 'user', () ->
    console.log 'user event: ', arguments

steamClient.on 'chatStateChange', () ->
    console.log 'chatStateChange event: ', arguments

steamClient.on 'richPresence', () ->
    console.log 'user event: ', arguments
#

dotaClient.on 'unready', ->
    console.log 'Dota2Client unready'

steamClient.on 'loggedOn', ->
    console.log 'Logged in to Steam.'
    steamClient.setPersonaState(Steam.EPersonaState.Online)
    dotaClient.launch()

##########

irc2zmq.subscribe ''
irc2zmq.on 'message', (rawMsg) ->
    msg = JSON.parse rawMsg
    switch msg.command
        when "say"
            formatted = Util.format('<%s> %s', msg.from, msg.message)
            dotaClient.sendMessage(config.dotaChannel, formatted)
        else
            console.log "Unknown irc2zmq message: ", msg

dotaClient.on 'ready', ->
    console.log 'Dota2Client ready'
    dotaClient.joinChat config.dotaChannel

dotaClient.on 'chatMessage', (channel, sender, message) ->
    formatted = Util.format('<%s> %s', sender, message)
    zmqObj =
        command: "say",
        to: config.ircChannel,
        message: formatted,
    zmq2irc.send(JSON.stringify zmqObj)
    console.log zmqObj

steamClient.logOn(
    accountName: config.username,
    password: config.password,
)
