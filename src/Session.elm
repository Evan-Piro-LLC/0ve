module Session exposing (Session, new, toAccount, toAccountName, toKey)

import Account exposing (Account)
import Browser.Navigation as Browser


type alias Session =
    { key : Browser.Key
    , account : Account
    }


new : Browser.Key -> Account -> Session
new key acc =
    { key = key, account = acc }


toAccount : Session -> Account
toAccount session =
    session.account


toAccountName : Session -> String
toAccountName session =
    session
        |> toAccount
        |> Account.toName


toKey : Session -> Browser.Key
toKey session =
    session.key
