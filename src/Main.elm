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
import Element as E
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
    E.layout [] <|
        E.column [ E.padding 30, E.spacing 30, E.width E.fill ] <|
            [ E.row
                [ E.spacing 10, E.width E.fill ]
                [ Input.button [] { onPress = Just Add, label = E.text "Add" }
                , Input.text [ onEnter Add ]
                    { onChange = Change
                    , text = model.text
                    , placeholder =
                        Just <| Input.placeholder [] <| E.text "Reminder"
                    , label = Input.labelHidden "Reminder"
                    }
                , E.link [ Font.color <| E.rgb 0 0 238 ]
                    { url = "https://github.com/kraai/reminders"
                    , label = E.text "Reminders"
                    }
                ]
            ]
                ++ viewError model.error
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


viewError : Maybe String -> List (E.Element Msg)
viewError error =
    case error of
        Just error_ ->
            [ E.el [ Font.color (E.rgb 1 0 0) ] (E.text error_) ]

        Nothing ->
            []


viewReminder : String -> E.Element Msg
viewReminder reminder =
    Keyed.el []
        ( reminder
        , E.row [ E.spacing 10 ]
            [ Input.checkbox []
                { onChange = \_ -> Delete reminder
                , icon = Input.defaultCheckbox
                , checked = False
                , label = Input.labelHidden "Delete"
                }
            , toElement reminder
            ]
        )


toElement : String -> E.Element Msg
toElement content =
    let
        parts =
            String.split "*" content

        italicizeEven spans =
            case spans of
                [] ->
                    []

                span :: rest ->
                    E.text span :: italicizeOdd rest

        italicizeOdd spans =
            case spans of
                [] ->
                    []

                span :: rest ->
                    E.el [ Font.italic ] (E.text span) :: italicizeEven rest
    in
    E.row [] <| italicizeEven parts
