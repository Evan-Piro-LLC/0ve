module ColorButtons exposing (col, colorButton, colorButtons, getShadowColor, sizeControls, view)

import Color exposing (Color)
import Html exposing (Html, button, div)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)


view : (Color -> msg) -> (Int -> msg) -> Int -> Color -> Int -> Html msg
view selectColor selectSize width color size =
    div
        [ style "max-width" (String.fromInt (width - 20) ++ "px")
        , style "padding" "10px"
        ]
        [ sizeControls selectSize color size
        , colorButtons selectColor color
        ]


sizeControls : (Int -> msg) -> Color -> Int -> Html msg
sizeControls selectMsg selectedColor selectedSize =
    let
        brushes =
            6

        inc =
            10

        buttonSize =
            brushes * inc

        controls =
            List.range 0 brushes
                |> List.map
                    (\i ->
                        let
                            size =
                                max 2 (i * inc)
                        in
                        button
                            [ style "-webkit-appearance" "none"
                            , style "-moz-appearance" "none"
                            , style "display" "block"
                            , style "background-color" "transparent"
                            , style "border" "none"
                            , style "margin" "5px"
                            , style "padding" "0"
                            , style "min-width" (String.fromInt 30 ++ "px")
                            , style "min-height" (String.fromInt buttonSize ++ "px")
                            , style "outline" "none"
                            , onClick (selectMsg size)
                            ]
                            [ div
                                [ style "border-radius" "50%"
                                , style "background-color" (Color.toCssString selectedColor)
                                , style "border" ("3px solid " ++ (Color.white |> getShadowColor |> Color.toCssString))
                                , style "width" (String.fromInt size ++ "px")
                                , style "height" (String.fromInt size ++ "px")
                                , style "margin" "0 auto"
                                , style "box-shadow"
                                    (if selectedSize == size then
                                        "rgba(0, 0, 0, 0.4) 0px 4px 6px"

                                     else
                                        "none"
                                    )
                                , style "transition" "transform 0.2s linear"
                                , style "transform"
                                    (if selectedSize == size then
                                        "translateY(-6px)"

                                     else
                                        "none"
                                    )
                                ]
                                []
                            ]
                    )
    in
    div
        [ style "display" "flex"
        , style "flex-direction" "row"
        , style "justify-content" "space-around"
        , style "align-items" "center"
        ]
        controls


getShadowColor : Color -> Color
getShadowColor color =
    let
        { red, green, blue } =
            Color.toRgba color
    in
    Color.rgba red green blue 0.2


colorButtons : (Color -> msg) -> Color -> Html msg
colorButtons selectColor selectedColor =
    let
        layout colors =
            colors
                |> List.map (List.map (colorButton selectColor selectedColor) >> col)
    in
    div
        [ style "display" "flex"
        , style "flex-direction" "row"
        , style "justify-content" "space-around"
        ]
    <|
        layout
            [ [ Color.lightRed
              , Color.red
              , Color.darkRed
              ]
            , [ Color.lightOrange
              , Color.orange
              , Color.darkOrange
              ]
            , [ Color.lightYellow
              , Color.yellow
              , Color.darkYellow
              ]
            , [ Color.lightGreen
              , Color.green
              , Color.darkGreen
              ]
            , [ Color.lightBlue
              , Color.blue
              , Color.darkBlue
              ]
            , [ Color.lightPurple
              , Color.purple
              , Color.darkPurple
              ]
            , [ Color.lightBrown
              , Color.brown
              , Color.darkBrown
              ]
            , [ Color.white
              , Color.lightGrey
              , Color.grey
              ]
            , [ Color.darkGrey
              , Color.lightCharcoal
              , Color.charcoal
              ]
            , [ Color.darkCharcoal
              , Color.black
              ]
            ]


col : List (Html msg) -> Html msg
col btns =
    div [] btns


colorButton : (Color -> msg) -> Color -> Color -> Html msg
colorButton selectColor selectedColor color =
    button
        [ style "border-radius" "50%"
        , style "background-color" (Color.toCssString color)
        , style "display" "block"
        , style "width" "40px"
        , style "height" "40px"
        , style "margin" "5px"
        , style "border" "2px solid white"
        , style "box-shadow"
            (if selectedColor == color then
                "rgba(0, 0, 0, 0.4) 0px 4px 6px"

             else
                "none"
            )
        , style "transition" "transform 0.2s linear"
        , style "outline" "none"
        , style "transform"
            (if selectedColor == color then
                "translateY(-6px)"

             else
                "none"
            )
        , onClick (selectColor color)
        ]
        []
