-- Copyright 2021 Matthew James Kraai
--
-- Reminders is free software: you can redistribute it and/or modify it
-- under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- Reminders is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public
-- License along with Reminders.  If not, see
-- <https://www.gnu.org/licenses/>.


port module Main exposing (..)

import Browser
import Element
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
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
    , error : Maybe String
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
    ( Model reminders "" Nothing, Cmd.none )



-- UPDATE


type Msg
    = Add
    | Change String
    | Delete String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Add ->
            if String.isEmpty model.text then
                ( { model | error = Just "That reminder is empty.  Please enter a non-empty reminder." }, Cmd.none )

            else if List.member model.text model.reminders then
                ( { model | error = Just "That reminder already exists.  Please add a new reminder." }, Cmd.none )

            else
                let
                    reminders =
                        model.text :: model.reminders
                in
                ( Model reminders "" Nothing, save (Encode.list Encode.string reminders) )

        Change text ->
            ( { model | text = text, error = Nothing }, Cmd.none )

        Delete reminder ->
            let
                reminders =
                    List.filter ((/=) reminder) model.reminders
            in
            ( Model reminders "" Nothing, save (Encode.list Encode.string reminders) )



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.main_ []
        [ Element.layout [] <|
            Element.column
                [ Element.padding 30
                , Element.spacing 30
                , Element.width Element.fill
                ]
            <|
                [ Element.row
                    [ Element.spacing 10, Element.width Element.fill ]
                    [ Input.button []
                        { onPress = Just Add
                        , label = Element.text "Add"
                        }
                    , Input.text [ onEnter Add ]
                        { onChange = Change
                        , text = model.text
                        , placeholder =
                            Just <| Input.placeholder [] <| Element.text "Reminder"
                        , label = Input.labelHidden "Reminder"
                        }
                    , Element.link [ Font.color <| Element.rgb 0 0 238 ]
                        { url = "https://github.com/kraai/reminders"
                        , label = Element.text "Reminders"
                        }
                    ]
                ]
                    ++ viewError model.error
                    ++ List.map viewReminder model.reminders
        ]


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
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


viewError : Maybe String -> List (Element.Element Msg)
viewError error =
    case error of
        Just error_ ->
            [ Element.el [ Font.color (Element.rgb 1 0 0) ]
                (Element.text error_)
            ]

        Nothing ->
            []


viewReminder : String -> Element.Element Msg
viewReminder reminder =
    Keyed.el []
        ( reminder
        , Element.row [ Element.spacing 10 ]
            [ Input.checkbox []
                { onChange = \_ -> Delete reminder
                , icon = Input.defaultCheckbox
                , checked = False
                , label = Input.labelHidden "Delete"
                }
            , toElement reminder
            ]
        )


toElement : String -> Element.Element Msg
toElement content =
    let
        parts =
            String.split "*" content

        italicizeEven spans =
            case spans of
                [] ->
                    []

                span :: rest ->
                    Element.text span :: italicizeOdd rest

        italicizeOdd spans =
            case spans of
                [] ->
                    []

                span :: rest ->
                    Element.el [ Font.italic ] (Element.text span)
                        :: italicizeEven rest
    in
    Element.row [] <| italicizeEven parts
