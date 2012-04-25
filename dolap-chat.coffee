socket = new WebSocket "ws://0.0.0.0:3000"

send = (msg) ->
    console.log "SENT MSG: " + msg
    socket.send msg

#socket.onopen = () ->

socket.onmessage = (evt) ->
    msg = evt.data
    console.log "GOT MSG: " + msg
    handle_msg msg

socket.onclose = (e) ->
    for channel in Object.keys(channels)
        term = $("#" + channel).terminal().error "Disconnected."

socket.onerror = (e) ->
    console.log "error: " + e.code
    $("#oda").terminal().error "error: " + e.code


class Parser
    constructor: (@text) ->
        @rest = jQuery.trim text

    get_next_token: ->
        space_idx = @rest.indexOf ' '
        if space_idx == -1
            r = @rest
            @rest = ""
            return r

        r = @rest.slice 0, space_idx
        @rest = jQuery.trim @rest.slice space_idx+1
        r

    get_rest: ->
        @rest


handle_msg = (msg) ->
    parser = new Parser msg
    cmd = parser.get_next_token()

    if cmd == 'msg'
        from = parser.get_next_token()
        chan = parser.get_next_token()
        chan_element = $("#" + chan)
        m = parser.get_rest()
        if from != nick
            chan_element.terminal().echo from + '> ' + m
    else if cmd == 'join'
        user = parser.get_next_token()
        chan = parser.get_next_token()
        chan_element = $("#" + chan)
        chan_element.data('channel').add_user user
        chan_element.terminal().echo user + ' has joined the channel.'
    else if cmd == 'leave'
        user = parser.get_next_token()
        chan = parser.get_next_token()
        chan_element = $("#" + chan)
        chan_element.data('channel').remove_user user
        chan_element.terminal().echo user + " has left the channel."
    else if cmd == "users"
        chan = parser.get_next_token()
        users = parser.get_rest().split(',')
        try_join_channel(chan)
        console.log channels.chan
        console.log(Object.keys(channels))
        console.log typeof channels.chan
        channels[chan].set_users(users)
    else if cmd == "login"
        t1 = parser.get_next_token()
        if t1 == 'ok'
            login_ok()
        else if t1 == 'nickinuse'
            $("#login-text").html "Nick is in use."


channels = {}
current_channel = undefined
nick = undefined

class Channel
    constructor: (@name) ->
        @users = []

        $("#terminals").append '<div id="' + name + '"></div>'

        term_func = (command, term) ->
            if command[0] == "/"
                send(command[1..])
            else
                send "msg " + name + " " + command


        jQuery ($, _) ->
            $("#" + name).terminal(term_func,
                greetings: 'Channel: ' + name
                name: name
                prompt: nick + '> '
            )

        tab_name = name + "_tab"
        $("#tabs").append '<li id="' + tab_name + '"><a>' + name + ' <span id="close-' + name + '"> [x]</a>' \
                            + '</span></li>'

        $("#" + tab_name).click ->
            switch_channel(channels[name])

        $("#close-" + name).click ->
            if current_channel == name
                leave_channel name

        $("#" + name).data('channel', this)


    add_user: (nick) ->
        @users.push nick
        if @name is current_channel
            update_user_info_div @users

    set_users: (nicks) ->
        @users = []
        @users.push nick for nick in nicks
        if @name is current_channel
            update_user_info_div @users

    remove_user: (nick) ->
        # TODO: find an idiomatic way to remove from array in coffeescript
        @users = @users[(@users.indexOf nick)..0]
        if @name == current_channel
            update_user_info_div @users

try_join_channel = (name) ->
    console.log "try_join_channel: " + name
    if channels[name] == undefined
        channels[name] = new Channel name
        console.log "channel object after try_join_channel: " + channels.name
        console.log "channel name that inserted to the map: " + name
    else
        console.log "already joined that channel: " + channels[name]

    switch_channel channels[name]

leave_channel = (name) ->
    send "leave " + name
    $("#" + name).remove()
    $("#" + name + "_tab").remove()

    channels[name] = undefined
    switch_channel Object.keys(channels)[0]

switch_channel = (chan) ->
    console.log("switching channel: " + chan)
    console.log("which has the name of: " + chan.name)
    name = chan.name
    for channame in Object.keys(channels)
        $("#" + channame).hide()
        $("#" + channame + "_tab").removeAttr "class"

    $("#" + name).show()
    $("#" + name + "_tab").attr("class", "active")
    scroll_bottom name

    current_channel = name
    update_user_info_div($("#" + name).data('channel').users)

scroll_bottom = (channel_name) ->
    t = $("#" + channel_name).terminal()
    t.scroll t.height()

update_user_info_div = (users) ->
    $("#info").html ""
    $("#info").append "<h2>Users</h2>"

    for i in [0..users.length-1]
        if i != 0
            $("#info").append "<br>"
        $("#info").append(users[i])
        
login_ok = ->
    $("#login-text").html ""
    $("#login-modal").modal "hide"
    setTimeout (->
        send "join oda"), 100

$(document).ready ->
    $("#login-modal").modal 'show'
    $("#login-btn").click ->
        $("#login-text").html "Logging in.."
        send "login " + $("#nick-input").val()
        nick = $("#nick-input").val()

    $("#register-btn").click ->
        console.log "ok"
        $("#login-modal").modal 'hide'
        setTimeout (->
            $("#register-modal").modal 'show'), 300

        $("#cancel-register-btn").click ->
            $("#register-modal").modal 'hide'
            setTimeout (->
                $("#login-modal").modal 'show'), 300

        $("#register-accept-btn").click ->
            nick = $("#nick-accept-btn").val()
            pwd = $("#password-input-1").val()
            pwd2 = $("#password-input-2").val()
            err = false
            if pwd != pwd2
                $("#password-input-group-1").addClass "error"
                $("#password-error-span1").html "Passwords doesn't match."
                $("#password-input-group-2").addClass "error"
                err = true
            else
                $("#password-input-group-1").removeClass "error"
                $("#password-input-group-2").removeClass "error"
                $("#password-error-span1").html ""

            if nick.length < 4
                $("#nick-error-span").html "Nick should be longer than 3 characters."
                $("#nick-input-group").addClass "error"
                error = true
            else
                $("#nick-error-span").html ""
                $("#nick-input-group").removeClass "error"

            if !err
                $("#register-form-help-block").html "Register...."

            console.log "accept register"

    $("#join-channel").click ->
        $("#" + current_channel).terminal().insert "/join "

    $("#info").draggable()





