module Person exposing
    ( Model
    , Msg(..)
    , init
    , subscriptions
    , toSession
    , update
    , view
    )

import Asset
import Brand
import Css exposing (hover)
import File exposing (File)
import File.Select as Select
import Html.Styled exposing (Html, a, button, div, img, text, textarea)
import Html.Styled.Attributes exposing (href, placeholder, src, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import LinkedText
import Loading
import Ports
import Route
import Session exposing (Session)
import Storage
import Svg.Styled.Attributes exposing (css)
import Tailwind.Breakpoints as Breakpoints
import Tailwind.Utilities as T


type alias Model =
    { session : Session
    , account : String
    , loading : Maybe String
    , person : Maybe Ports.GetPersonResp
    , editText : Maybe String
    , editCid : Maybe String
    }


toSession : Model -> Session
toSession =
    .session


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.gotPerson GotPerson


init : Session -> String -> ( Model, Cmd Msg )
init session account =
    ( { session = session
      , account = account
      , loading = Just "Loading person"
      , person = Nothing
      , editText = Nothing
      , editCid = Nothing
      }
    , Ports.getPerson account
    )


personView : Model -> Ports.GetPersonResp -> Html Msg
personView model person =
    div []
        [ div [ css [ Breakpoints.sm [ T.flex, T.flex_row, T.items_start, T.gap_12 ] ] ]
            [ viewImage model person
            , div
                [ css [ T.flex_1 ] ]
                [ accountName model
                , case model.editText of
                    Just info ->
                        textarea
                            [ Brand.input, Brand.textarea, css [ T.mt_6 ], value info, onInput TextUpdated, placeholder "Add some info about you!" ]
                            []

                    Nothing ->
                        div
                            [ css [ T.mt_6 ] ]
                            [ person.text
                                |> Maybe.withDefault "No info"
                                |> LinkedText.linkedText
                                |> div [ css [ T.leading_relaxed ] ]
                            ]
                ]
            ]
        , friendsView person.friends
        ]


viewImage : Model -> Ports.GetPersonResp -> Html Msg
viewImage model person =
    let
        size =
            css [ T.flex_initial, T.h_32 ]
    in
    case ( model.editText, model.editCid, person.cid ) of
        ( Just _, Nothing, _ ) ->
            img [ size, css [ hover [ T.cursor_pointer ] ], onClick FileRequested, Asset.toAttr Asset.addSmall ] []

        ( Just _, Just cid, _ ) ->
            img [ size, src <| Storage.cidToFileUrl cid ] []

        ( _, _, Just cid ) ->
            img [ size, src <| Storage.cidToFileUrl cid ] []

        ( _, _, _ ) ->
            img [ size, Asset.toAttr Asset.question ] []


accountName : Model -> Html Msg
accountName model =
    let
        buttons =
            case model.editText of
                Just _ ->
                    div [ css [ Breakpoints.sm [ T.flex, T.flex_row, T.gap_3 ] ] ]
                        [ button
                            [ css []
                            , Brand.greenButtonOutline
                            , onClick CloseEdit
                            ]
                            [ text "Cancel" ]
                        , button
                            [ css []
                            , Brand.greenButton
                            , value <| Maybe.withDefault "" model.editText
                            , onClick PutPerson
                            ]
                            [ text "Save" ]
                        ]

                Nothing ->
                    div []
                        [ button
                            [ css []
                            , Brand.greenButtonOutline
                            , onClick OpenEdit
                            ]
                            [ text "Edit" ]
                        ]
    in
    case Session.toAccountName model.session == model.account of
        True ->
            div [ css [ Breakpoints.sm [ T.flex, T.flex_row, T.items_start ] ] ]
                [ div [ css [ T.flex_1, T.font_bold ] ] [ text model.account ]
                , buttons
                ]

        False ->
            div [ css [ T.font_bold ] ] [ text model.account ]


friendsView : List String -> Html Msg
friendsView friends =
    div
        [ css [ T.font_bold, T.mt_6 ] ]
        [ friends
            |> List.length
            |> String.fromInt
            |> (\n -> "Friends (" ++ n ++ ")")
            |> text
            |> List.singleton
            |> div []
        , friends
            |> List.map friendPill
            |> div [ css [ T.flex, T.flex_wrap, T.my_5, T.gap_6 ] ]
        ]


friendPill : String -> Html msg
friendPill acc =
    a
        [ Brand.greenButtonOutline
        , css
            [ T.border, T.border_solid, T.border_green, T.py_3, T.px_5, T.block ]
        , acc
            |> Route.Person
            |> Route.toPath
            |> href
        ]
        [ text acc ]


respView : Model -> Html Msg
respView model =
    let
        account =
            Session.toAccountName model.session

        isOwner =
            model.account == account
    in
    model.person
        |> Maybe.map (personView model)
        |> Maybe.withDefault
            (case isOwner of
                True ->
                    button [ onClick PutPerson, Brand.greenButton, css [ T.text_center ] ] [ text "Make a Profile!" ]

                False ->
                    div [] [ text "Person not found" ]
            )


content : Model -> Html Msg
content model =
    case model.loading of
        Just message ->
            div [] [ Loading.loading ]

        Nothing ->
            respView model



--div [ css [ T.px_5, T.mx_5 ] ]


view : Model -> Html Msg
view model =
    div [ css [ T.my_14, T.mx_14 ] ] [ content model ]


type Msg
    = GotPerson (Maybe Ports.GetPersonResp)
    | PutPerson
    | OpenEdit
    | CloseEdit
    | TextUpdated String
    | FileChosen File
    | FileRequested
    | GotFileUploadResp (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPerson person ->
            ( { model | loading = Nothing, person = person, editText = Nothing, editCid = Nothing }, Cmd.none )

        PutPerson ->
            let
                accountCid =
                    model.person
                        |> Maybe.map (\person -> person.cid)
                        |> Maybe.withDefault Nothing

                sendCid =
                    if model.editCid == Nothing then
                        accountCid

                    else
                        model.editCid
            in
            ( { model | loading = Just "Saving..." }, Ports.putPerson { text = model.editText, cid = sendCid } )

        CloseEdit ->
            ( { model | editText = Nothing }, Cmd.none )

        OpenEdit ->
            let
                text =
                    model.person
                        |> Maybe.map (\p -> p.text)
                        |> Maybe.withDefault (Just "")
                        |> Maybe.withDefault ""
            in
            ( { model | editText = Just text }, Cmd.none )

        TextUpdated str ->
            ( { model | editText = Just str }, Cmd.none )

        FileRequested ->
            ( model, Select.file [ "image/jpeg", "image/png", "image/svg+xml", "text/plain" ] FileChosen )

        FileChosen file ->
            ( { model | loading = Just "File uploading..." }
            , Storage.uploadFile GotFileUploadResp file
            )

        GotFileUploadResp resp ->
            let
                cid =
                    Result.toMaybe resp
            in
            ( { model
                | loading = Nothing
                , editCid = cid
              }
            , Cmd.none
            )
