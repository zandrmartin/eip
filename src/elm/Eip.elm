module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Dom
import Dom.Scroll as Scroll
import Task
import Irc


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { input : String
    , connections : List Irc.Connection
    , activeConnection : Irc.Id
    , activeTarget : String
    }



-- INIT


init : ( Model, Cmd Msg )
init =
    ( { input = ""
      , connections = []
      , activeConnection = -1
      , activeTarget = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = InputKeyDown Irc.KeyEvent
    | TextInput String
    | InputBlurred
    | HandleIrcEventAction Irc.ActionEvent
    | HandleIrcEventDisconnect Irc.DisconnectEvent
    | HandleIrcEventError Irc.ErrorEvent
    | HandleIrcEventInvite Irc.InviteEvent
    | HandleIrcEventJoin Irc.JoinEvent
    | HandleIrcEventKick Irc.KickEvent
    | HandleIrcEventKill Irc.KillEvent
    | HandleIrcEventMessage Irc.MessageEvent
    | HandleIrcEventMinusMode Irc.ModeEvent
    | HandleIrcEventMotd Irc.MotdEvent
    | HandleIrcEventNames Irc.NamesEvent
    | HandleIrcEventNick Irc.NickEvent
    | HandleIrcEventNotice Irc.NoticeEvent
    | HandleIrcEventPart Irc.PartEvent
    | HandleIrcEventPlusMode Irc.ModeEvent
    | HandleIrcEventQuit Irc.QuitEvent
    | HandleIrcEventConnect Irc.ConnectEvent
    | HandleIrcEventSelfMessage Irc.SelfMessageEvent
    | HandleIrcEventTopic Irc.TopicEvent
    | HandleIrcEventWhois Irc.WhoisEvent
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleIrcEventAction e ->
            model ! []

        HandleIrcEventDisconnect e ->
            let
                conns =
                    List.filter (\c -> c.id /= e.connectionId) model.connections
            in
                ( { model | connections = conns }, Cmd.none )

        HandleIrcEventError e ->
            model ! []

        HandleIrcEventInvite e ->
            model ! []

        HandleIrcEventJoin e ->
            model ! []

        HandleIrcEventKick e ->
            model ! []

        HandleIrcEventKill e ->
            model ! []

        HandleIrcEventMessage e ->
            model ! []

        HandleIrcEventMinusMode e ->
            model ! []

        HandleIrcEventMotd e ->
            let
                messages =
                    List.map (Irc.Message "") (String.split "\n" e.motd)

                conns =
                    List.map
                        (\c ->
                            if c.id == e.connectionId then
                                { c | messages = c.messages ++ messages }
                            else
                                c
                        )
                        model.connections
            in
                ( { model | connections = conns }
                , scrollElementToBottom "chatwindow"
                )

        HandleIrcEventNames e ->
            model ! []

        HandleIrcEventNick e ->
            model ! []

        HandleIrcEventNotice e ->
            model ! []

        HandleIrcEventPart e ->
            model ! []

        HandleIrcEventPlusMode e ->
            model ! []

        HandleIrcEventQuit e ->
            model ! []

        HandleIrcEventConnect e ->
            let
                conn =
                    Irc.Connection e.connectionId e.server e.nick [] []

                conns =
                    model.connections ++ [ conn ]

                mod =
                    { model
                        | connections = conns
                        , activeConnection = conn.id
                    }
            in
                ( mod, Cmd.none )

        HandleIrcEventSelfMessage e ->
            model ! []

        HandleIrcEventTopic e ->
            model ! []

        HandleIrcEventWhois e ->
            model ! []

        InputKeyDown e ->
            if e.key == "Enter" && model.input /= "" then
                let
                    conn =
                        model.activeConnection

                    target =
                        model.activeTarget

                    input =
                        model.input
                in
                    ( { model | input = "" }
                    , Irc.processCommand conn target input
                    )
            else if e.key == "Tab" then
                if List.length (String.words model.input) == 1 then
                    if String.startsWith "/" model.input then
                        ( { model | input = Irc.completeCommand model.input }
                        , Cmd.none
                        )
                    else
                        -- nick completion goes here; fill this in later
                        model ! []
                else
                    model ! []
            else
                model ! []

        TextInput s ->
            ( { model | input = s }, Cmd.none )

        InputBlurred ->
            model ! [ focusElement "chatinput" ]

        _ ->
            model ! []


focusElement : String -> Cmd Msg
focusElement id =
    Task.attempt (\_ -> NoOp) (Dom.focus id)


scrollElementToBottom : String -> Cmd Msg
scrollElementToBottom id =
    Task.attempt (\_ -> NoOp) (Scroll.toBottom id)



-- VIEW


view : Model -> Html Msg
view model =
    let
        messages =
            case List.head model.connections of
                Just c ->
                    c.messages

                Nothing ->
                    []
    in
        div [ id "app" ]
            [ viewTitleBar
            , viewSidebar model
            , viewChatWindow messages
            , viewChatInput model
            ]


viewChatInput : Model -> Html Msg
viewChatInput model =
    div [ id "chatinputbox" ]
        [ input
            [ type_ "text"
            , id "chatinput"
            , value model.input
            , onInput TextInput
            , autofocus True
            , onBlur InputBlurred
            ]
            []
        ]


viewChatWindow : List Irc.Message -> Html Msg
viewChatWindow messages =
    div [ id "chatwindow" ] (List.map (\m -> div [] [ text m.text ]) messages)


viewSidebar : Model -> Html Msg
viewSidebar model =
    div [ id "sidebar" ]
        (List.map (model |> viewSidebarConnection) model.connections)


viewSidebarConnection : Model -> Irc.Connection -> Html Msg
viewSidebarConnection model conn =
    div
        [ classList
            [ ( "connection-label", True )
            , ( "active", conn.id == model.activeConnection )
            ]
        ]
        ([ text conn.server ]
            ++ (List.map (viewSidebarChannel model) conn.channels)
        )


viewSidebarChannel : Model -> Irc.Channel -> Html Msg
viewSidebarChannel model chan =
    div
        [ classList
            [ ( "channel-label", True )
            , ( "active", chan.name == model.activeTarget )
            ]
        ]
        []


viewTitleBar : Html msg
viewTitleBar =
    div [ id "titlebar" ] []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Irc.eventAction HandleIrcEventAction
        , Irc.eventDisconnect HandleIrcEventDisconnect
        , Irc.eventError HandleIrcEventError
        , Irc.eventInvite HandleIrcEventInvite
        , Irc.eventJoin HandleIrcEventJoin
        , Irc.eventKick HandleIrcEventKick
        , Irc.eventKill HandleIrcEventKill
        , Irc.eventMessage HandleIrcEventMessage
        , Irc.eventMinusMode HandleIrcEventMinusMode
        , Irc.eventMotd HandleIrcEventMotd
        , Irc.eventNames HandleIrcEventNames
        , Irc.eventNick HandleIrcEventNick
        , Irc.eventNotice HandleIrcEventNotice
        , Irc.eventPart HandleIrcEventPart
        , Irc.eventPlusMode HandleIrcEventPlusMode
        , Irc.eventQuit HandleIrcEventQuit
        , Irc.eventConnect HandleIrcEventConnect
        , Irc.eventSelfMessage HandleIrcEventSelfMessage
        , Irc.eventTopic HandleIrcEventTopic
        , Irc.eventWhois HandleIrcEventWhois
        , Irc.inputKeyDown InputKeyDown
        ]
