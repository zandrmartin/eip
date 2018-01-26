port module Irc exposing (..)

import Time exposing (Time)


-- MODEL


type alias Id =
    Int


type alias Connection =
    { id : Id
    , server : String
    , nick : String
    , channels : List Channel
    , messages : List Message
    }


type alias Channel =
    { name : String
    , messages : List Message
    , nicks : List String
    }


type alias Message =
    { author : String
    , text : String

    -- FIGURE TIME OUT LATER
    -- just get it from the port, forget trying to do it in elm, it's a mess
    -- , time : Time
    }


commands : List String
commands =
    [ "connect"
    , "disconnect"
    , "join"
    , "leave"
    , "list"
    , "msg"
    , "part"
    , "query"
    , "quit"
    , "whois"
    ]


completeCommand : String -> String
completeCommand orig =
    let
        start =
            if String.startsWith "/" orig then
                ( "/", String.dropLeft 1 orig )
            else
                ( "", orig )

        filtered =
            List.filter (String.startsWith (Tuple.second start)) commands
    in
        case (List.head filtered) of
            Just a ->
                Tuple.first start ++ a

            Nothing ->
                orig



-- PORTS


port connectToServer : { server : String, nick : String } -> Cmd msg


port join : { connection : Id, channel : String } -> Cmd msg


port part : { connection : Id, channel : String, message : String } -> Cmd msg


port say : { connection : Id, target : String, message : String } -> Cmd msg


port whois : { connection : Id, nick : String } -> Cmd msg


port list : { connection : Id } -> Cmd msg


port disconnect : { connection : Id, message : String } -> Cmd msg


processCommand : Id -> String -> String -> Cmd msg
processCommand conn target cmd =
    if cmd == "" then
        Cmd.none
    else if String.startsWith "/" cmd then
        let
            words =
                Debug.log "words"
                    (cmd |> String.dropLeft 1 |> String.words)

            command =
                Debug.log "command"
                    (words
                        |> List.head
                        |> Maybe.withDefault "say"
                        |> String.toLower
                    )

            argList =
                Debug.log "argList"
                    (words |> List.tail |> Maybe.withDefault [])

            argString =
                Debug.log "argString"
                    (String.join " " argList)
        in
            case command of
                "connect" ->
                    if List.length words < 2 then
                        Cmd.none
                    else
                        let
                            server =
                                argList
                                    |> List.head
                                    |> Maybe.withDefault ""

                            nick =
                                argList
                                    |> List.reverse
                                    |> List.head
                                    |> Maybe.withDefault ""
                        in
                            connectToServer { server = server, nick = nick }

                "join" ->
                    if argString == "" then
                        Cmd.none
                    else
                        join { connection = conn, channel = argString }

                "part" ->
                    part
                        { connection = conn
                        , channel = target
                        , message = argString
                        }

                "leave" ->
                    part
                        { connection = conn
                        , channel = target
                        , message = argString
                        }

                "whois" ->
                    whois { connection = conn, nick = argString }

                "list" ->
                    list { connection = conn }

                "disconnect" ->
                    disconnect { connection = conn, message = argString }

                "quit" ->
                    disconnect { connection = conn, message = argString }

                _ ->
                    say
                        { connection = conn
                        , target = target
                        , message = argString
                        }
    else
        say
            { connection = conn
            , target = target
            , message = cmd
            }



-- EVENTS


type alias ActionEvent =
    { connectionId : Id
    , from : String
    , to : String
    , text : String
    }


type alias DisconnectEvent =
    { connectionId : Id }


type alias ErrorEvent =
    { connectionId : Id
    , prefix : String
    , server : String
    , command : String
    , rawCommand : String
    , commandType : String
    , args : List String
    }


type alias InviteEvent =
    { connectionId : Id
    , channel : String
    , from : String
    }


type alias JoinEvent =
    { connectionId : Id, channel : String, nick : String }


type alias KickEvent =
    { connectionId : Id
    , channel : String
    , nick : String
    , by : String
    , reason : String
    }


type alias KillEvent =
    { connectionId : Id
    , nick : String
    , reason : String
    , channels : List String
    }


type alias MessageEvent =
    { connectionId : Id
    , nick : String
    , to : String
    , text : String
    }


type alias MotdEvent =
    { connectionId : Id, motd : String }


type alias NamesEvent =
    { connectionId : Id
    , channel : String
    , nicks : List { nick : String, mode : String }
    }


type alias NickEvent =
    { connectionId : Id
    , oldnick : String
    , newnick : String
    , channels : List String
    }


type alias NoticeEvent =
    { connectionId : Id
    , nick : String
    , to : String
    , text : String
    }


type alias PartEvent =
    { connectionId : Id
    , channel : String
    , nick : String
    , reason : String
    }


type alias ModeEvent =
    { connectionId : Id
    , channel : String
    , by : String
    , mode : String
    , argument : String
    }


type alias QuitEvent =
    { connectionId : Id
    , nick : String
    , reason : String
    , channels : List String
    }


type alias ConnectEvent =
    { connectionId : Id
    , nick : String
    , server : String
    }


type alias SelfMessageEvent =
    { connectionId : Id
    , to : String
    , text : String
    }


type alias TopicEvent =
    { connectionId : Id
    , channel : String
    , topic : String
    , nick : String
    }


type alias WhoisEvent =
    { connectionId : Id
    , nick : String
    , user : String
    , host : String
    , realname : String
    , channels : List String
    , server : String
    , serverinfo : String
    , idle : String
    }


port eventConnect : (ConnectEvent -> msg) -> Sub msg


port eventMotd : (MotdEvent -> msg) -> Sub msg


port eventNames : (NamesEvent -> msg) -> Sub msg


port eventTopic : (TopicEvent -> msg) -> Sub msg


port eventJoin : (JoinEvent -> msg) -> Sub msg


port eventPart : (PartEvent -> msg) -> Sub msg


port eventQuit : (QuitEvent -> msg) -> Sub msg


port eventKick : (KickEvent -> msg) -> Sub msg


port eventKill : (KillEvent -> msg) -> Sub msg


port eventMessage : (MessageEvent -> msg) -> Sub msg


port eventSelfMessage : (SelfMessageEvent -> msg) -> Sub msg


port eventNotice : (NoticeEvent -> msg) -> Sub msg


port eventNick : (NickEvent -> msg) -> Sub msg


port eventInvite : (InviteEvent -> msg) -> Sub msg


port eventPlusMode : (ModeEvent -> msg) -> Sub msg


port eventMinusMode : (ModeEvent -> msg) -> Sub msg


port eventWhois : (WhoisEvent -> msg) -> Sub msg


port eventAction : (ActionEvent -> msg) -> Sub msg


port eventError : (ErrorEvent -> msg) -> Sub msg


port eventDisconnect : (DisconnectEvent -> msg) -> Sub msg



-- tab/enter in input; no good way to do this in elm yet


type alias KeyEvent =
    { key : String
    , altKey : Bool
    , ctrlKey : Bool
    , metaKey : Bool
    }


port inputKeyDown : (KeyEvent -> msg) -> Sub msg
