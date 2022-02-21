port module Thread exposing
    ( AccountReaction
    , AddPostArg
    , Model
    , Msg(..)
    , Post
    , ThreadName(..)
    , addPost
    , createPost
    , init
    , monthToStr
    , postView
    , reactButton
    , reactToPost
    , subscription
    , timeToDate
    , toSession
    , unreactToPost
    , update
    , view
    )

import Account exposing (Account)
import Asset
import Brand
import Css exposing (hover)
import File exposing (File)
import File.Select as Select
import Html.Styled exposing (Html, a, button, div, fromUnstyled, h1, h3, h4, h5, h6, img, input, text, textarea, toUnstyled)
import Html.Styled.Attributes as Attr exposing (css, href, placeholder, src, value)
import Html.Styled.Events exposing (onClick, onInput)
import Http
import Json.Decode as D exposing (Decoder, field, string)
import LinkedText
import List exposing (length)
import Loading
import Route
import Session exposing (Session)
import Storage
import Tailwind.Utilities as T
import Time exposing (Month(..), Posix, millisToPosix, toDay, toHour, toMinute, toMonth, toSecond, toYear, utc)


port addPost : AddPostArg -> Cmd msg


port getThread : String -> Cmd msg


port gotThread : (List Post -> msg) -> Sub msg


port reactToPost : ReactToPostArgs -> Cmd msg


port unreactToPost : ReactToPostArgs -> Cmd msg


type alias AddPostArg =
    { threadName : String
    , text : String
    , cid : Maybe String
    }


type alias ReactToPostArgs =
    { threadName : String
    , postId : String
    }


subscription : Model -> Sub Msg
subscription model =
    gotThread GotThread


type alias Post =
    { account : String
    , text : String
    , cid : Maybe String
    , id : String
    , created_timestamp : Int
    , reactions : List AccountReaction
    }


type alias AccountReaction =
    { reaction : String
    , created_timestamp : Int
    , account : String
    }



---- MODEL ----


type alias Model =
    { post : String
    , cid : Maybe String
    , isLoading : Bool
    , posts : List Post
    , file : Maybe File
    , logs : String
    , name : String
    , threadLoading : Bool
    , session : Session
    }


toSession : Model -> Session
toSession model =
    model.session


type ThreadName
    = ThreadName String


init : Session -> ThreadName -> ( Model, Cmd Msg )
init session (ThreadName name) =
    ( { post = ""
      , cid = Nothing
      , isLoading = True
      , posts = []
      , file = Nothing
      , logs = ""
      , name = name
      , threadLoading = True
      , session = session
      }
    , getThread name
    )



---- UPDATE ----


type Msg
    = AddPost
    | PostUpdated String
    | GotThread (List Post)
    | ReactToPost String
    | UnreactToPost String
    | GotFileUploadResp (Result Http.Error String)
    | FileChosen File
    | FileRequested


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddPost ->
            case model.post of
                "" ->
                    ( model, Cmd.none )

                _ ->
                    ( { model | post = "", isLoading = True, cid = Nothing }
                    , addPost { threadName = model.name, text = model.post, cid = model.cid }
                    )

        PostUpdated str ->
            ( { model | post = str }, Cmd.none )

        FileChosen file ->
            ( model
            , Storage.uploadFile GotFileUploadResp file
            )

        GotThread posts ->
            ( { model | posts = posts, isLoading = False }, Cmd.none )

        GotFileUploadResp resp ->
            let
                cid =
                    Result.toMaybe resp
            in
            ( { model | isLoading = False, cid = cid }, Cmd.none )

        ReactToPost id ->
            ( { model | isLoading = True }, reactToPost { threadName = model.name, postId = id } )

        UnreactToPost id ->
            ( { model | isLoading = True }, unreactToPost { threadName = model.name, postId = id } )

        FileRequested ->
            ( model, Select.file [ "image/jpeg", "image/png", "image/svg+xml", "text/plain" ] FileChosen )



---- VIEW ----


view : Model -> Html Msg
view model =
    case model.isLoading of
        True ->
            Loading.loading

        False ->
            let
                posts =
                    case model.posts of
                        [] ->
                            div [] [ text "Nothing yet." ]

                        _ ->
                            div [] (List.map (postView <| Session.toAccount model.session) model.posts)
            in
            div [ css [ T.px_5 ] ]
                [ h1 [] [ text model.name ]
                , createPost model
                , h3 [] [ text "Feed" ]
                , posts
                ]


createPost : Model -> Html Msg
createPost model =
    div []
        [ h3 [] [ text "Create Post" ]
        , textEditor model
        ]


textEditor : Model -> Html Msg
textEditor model =
    let
        imagePreview =
            model.cid
                |> Maybe.map (\cid -> div [] [ img [ css [ T.max_h_36 ], src <| Storage.cidToFileUrl cid ] [] ])
                |> Maybe.withDefault (div [] [])

        submitRow =
            div [ Brand.row, css [ T.my_2 ] ]
                [ div [ css [ T.flex_1 ] ] [ button [ onClick AddPost, Brand.greenButton ] [ text "Add Post" ] ]
                , button [ onClick FileRequested, css [ T.border_none, T.bg_white ] ]
                    [ img
                        [ Asset.toAttr Asset.mountains
                        , css [ T.align_middle, T.w_6, T.shadow_sm, hover [ T.cursor_pointer ] ]
                        ]
                        []
                    ]
                ]
    in
    div [ Brand.input, css [ T.bg_white ] ] <|
        case model.isLoading of
            False ->
                [ textarea
                    [ onInput PostUpdated
                    , value model.post
                    , Brand.textarea
                    , css [ T.w_full, T.box_border, T.my_3, T.border_none, T.bg_white ]
                    , placeholder "Post some stuff."
                    ]
                    []
                , imagePreview
                , submitRow
                ]

            True ->
                [ div [] [ Loading.loading ] ]


postView : Account -> Post -> Html Msg
postView account post =
    let
        image =
            post.cid
                |> Maybe.map
                    (\url ->
                        div [ css [ T.overflow_hidden ] ]
                            [ img
                                [ Attr.css [ T.object_scale_down, T.w_48 ]
                                , src <| Storage.cidToFileUrl url
                                ]
                                []
                            ]
                    )
                |> Maybe.withDefault (div [] [])
    in
    div [ Brand.greenFrame ]
        [ div [ Brand.row ]
            [ a
                [ Brand.a
                , css [ T.font_bold, T.text_black, hover [ T.underline ] ]
                , href (Route.toPath (Route.Person post.account))
                ]
                [ text post.account ]
            , div [ css [ T.flex_1, T.text_right ] ]
                [ post.created_timestamp
                    |> toFloat
                    |> (\n -> n / 1000000)
                    |> round
                    |> millisToPosix
                    |> timeToDate
                    |> text
                ]
            ]
        , div [ Attr.css [ T.my_4 ] ] <| LinkedText.linkedText post.text
        , image
        , div [ Brand.row ]
            [ img [ Asset.toAttr Asset.like ] []
            , div [ css [ T.text_green, T.font_bold, T.mx_1 ] ]
                [ post.reactions
                    |> length
                    |> String.fromInt
                    |> text
                ]
            , div [ css [ T.mx_1, T.text_green ] ] [ reactButton (Account.toName account) post ]
            ]
        ]


reactButton : String -> Post -> Html Msg
reactButton account post =
    let
        isLike =
            post.reactions
                |> List.filter (\n -> n.account == account)
                |> List.isEmpty
                |> not
    in
    case isLike of
        True ->
            div
                [ onClick <| UnreactToPost post.id
                , Brand.greenButtonOutline
                ]
                [ text "-" ]

        False ->
            div
                [ onClick <| ReactToPost post.id
                , Brand.greenButtonOutline
                ]
                [ text "+" ]


monthToStr : Month -> String
monthToStr month =
    case month of
        Jan ->
            "January"

        Feb ->
            "February"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"


timeToDate : Posix -> String
timeToDate time =
    (monthToStr <| toMonth utc time)
        ++ " "
        ++ String.fromInt (toDay utc time)
        ++ ", "
        ++ String.fromInt (toYear utc time)
