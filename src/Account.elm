module Account exposing
    ( Account(..)
    , new
    , toName
    )


type Account
    = Account String


new : String -> Account
new name =
    Account name


toName : Account -> String
toName (Account name) =
    name
