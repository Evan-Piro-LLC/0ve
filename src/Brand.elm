module Brand exposing
    ( a
    , greenBorder
    , greenButton
    , greenButtonOutline
    , greenFrame
    , input
    , row
    , textarea
    )

import Css exposing (Style, hover, visited)
import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (css)
import Tailwind.Utilities as T


greenBorder : List Style
greenBorder =
    [ T.border
    , T.border_solid
    , T.border_green
    ]


greenFrame : Attribute msg
greenFrame =
    css <|
        greenBorder
            ++ [ T.border
               , T.border_solid
               , T.border_green
               , T.text_black
               , T.my_4
               , T.p_3
               ]


greenButtonOutline : Attribute msg
greenButtonOutline =
    css
        [ T.border
        , T.border_solid
        , T.border_green
        , T.rounded_md
        , T.text_green
        , T.px_3
        , T.py_1
        , T.rounded
        , T.bg_transparent
        , T.text_lg
        , hover [ T.cursor_pointer, T.bg_green, T.text_white, T.filter ]
        ]


greenButton : Attribute msg
greenButton =
    css
        [ T.rounded_md
        , T.text_white
        , T.bg_green
        , T.border
        , T.border_solid
        , T.border_green
        , T.px_5
        , T.py_1
        , T.rounded
        , T.text_lg
        , hover [ T.cursor_pointer, T.bg_dark_green ]
        ]


a : Attribute msg
a =
    css
        [ T.no_underline
        , T.text_black
        ]


input : Attribute msg
input =
    css <|
        greenBorder
            ++ [ T.bg_white
               , T.rounded_sm
               , T.px_3
               , T.py_2
               ]


textarea : Attribute msg
textarea =
    css [ T.w_full, T.box_border, T.my_3, T.h_full, T.resize_none, T.leading_relaxed, T.text_xl, T.p_3 ]


row : Attribute msg
row =
    css
        [ T.flex
        , T.flex_row
        , T.items_center
        ]
