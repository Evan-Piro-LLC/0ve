module Asset exposing
    ( Asset(..)
    , add
    , addSmall
    , assetPath
    , close
    , corgi
    , dog
    , hand
    , house
    , like
    , loading
    , logoRoundedWhite
    , mountains
    , post
    , profile
    , question
    , toAttr
    , upload
    )

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes exposing (src)


type Asset
    = Asset String


assetPath : String
assetPath =
    "/imgs/"


toAttr : Asset -> Attribute msg
toAttr (Asset filename) =
    src <| assetPath ++ filename


logoRoundedWhite : Asset
logoRoundedWhite =
    Asset "logo-rounded-white.svg"


like : Asset
like =
    Asset "like.svg"


post : Asset
post =
    Asset "post.svg"


loading : Asset
loading =
    Asset "loading.svg"


question : Asset
question =
    Asset "question.svg"


add : Asset
add =
    Asset "add.svg"


mountains : Asset
mountains =
    Asset "mountains.svg"


close : Asset
close =
    Asset "close.svg"


profile : Asset
profile =
    Asset "profile.svg"


dog : Asset
dog =
    Asset "dog.svg"


corgi : Asset
corgi =
    Asset "corgi.svg"


upload : Asset
upload =
    Asset "upload.svg"


house : Asset
house =
    Asset "house.svg"


hand : Asset
hand =
    Asset "hand.svg"


addSmall : Asset
addSmall =
    Asset "add-small.svg"
