port module Main exposing (..)

import Browser
import Element as E
import Element.Input as EI
import Html
import Html.Events
import Json.Decode as Decode
import Json.Encode as Encode



-- MAIN


main : Program Encode.Value Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = always Sub.none
        , update = update
        , view = view
        }



-- PORTS


port save : Encode.Value -> Cmd msg



-- MODEL


type alias Model =
    { reminders : List String
    , text : String
    }


init : Encode.Value -> ( Model, Cmd Msg )
init flags =
    let
        reminders =
            case Decode.decodeValue (Decode.list Decode.string) flags of
                Ok value ->
                    value

                Err _ ->
                    []
    in
    ( Model reminders "", Cmd.none )



-- UPDATE


type Msg
    = Add
    | Change String
    | Delete String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Add ->
            let
                reminders =
                    model.reminders ++ [ model.text ]
            in
            ( Model reminders "", save (Encode.list Encode.string reminders) )

        Change text ->
            ( { model | text = text }, Cmd.none )

        Delete reminder ->
            let
                reminders =
                    List.filter ((/=) reminder) model.reminders
            in
            ( Model reminders "", save (Encode.list Encode.string reminders) )



-- VIEW


view : Model -> Html.Html Msg
view model =
    E.layout [] <|
        E.column [ E.padding 30, E.spacing 30 ] <|
            [ E.row
                [ E.spacing 30 ]
                [ EI.text [ onEnter Add ]
                    { onChange = Change
                    , text = model.text
                    , placeholder = Just <| EI.placeholder [] <| E.text "Reminder"
                    , label = EI.labelHidden "Reminder"
                    }
                , EI.button [] { onPress = Just Add, label = E.text "Add" }
                ]
            ]
                ++ List.map viewReminder model.reminders


onEnter : msg -> E.Attribute msg
onEnter msg =
    E.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )


viewReminder : String -> E.Element Msg
viewReminder reminder =
    E.row [ E.spacing 10 ]
        [ EI.checkbox []
            { onChange = \_ -> Delete reminder
            , icon = EI.defaultCheckbox
            , checked = False
            , label = EI.labelHidden "Delete"
            }
        , E.text reminder
        ]
