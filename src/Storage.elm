module Storage exposing (cidToFileUrl, nftStorageApiKey, nftStorageUrl, uploadFile, uploadRespDecoder)

import File exposing (File)
import Http
import Json.Decode exposing (Decoder, field, string)


nftStorageApiKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDcyMDdkNjc3MDdBYzM3QjJhMmVBMzVFRTZENWQ0MDFhMUJjMjkxMDMiLCJpc3MiOiJuZnQtc3RvcmFnZSIsImlhdCI6MTY0MjE4MjU4MTMxOCwibmFtZSI6Ik5lYXIgSGFja2F0aG9uIn0.u29Ge2aT3C-xvz9k--s8dgzdYs-CMQ_8xQ-AaQgtjcU"


nftStorageUrl =
    "https://api.nft.storage/upload"


cidToFileUrl : String -> String
cidToFileUrl cid =
    "https://cloudflare-ipfs.com/ipfs/" ++ cid


uploadRespDecoder : Decoder String
uploadRespDecoder =
    field "value" (field "cid" string)


uploadFile : (Result Http.Error String -> msg) -> File -> Cmd msg
uploadFile gotFileMsg file =
    Http.request
        { method = "POST"
        , url = nftStorageUrl
        , headers = [ Http.header "Authorization" <| "Bearer " ++ nftStorageApiKey ]
        , body = Http.fileBody file
        , expect = Http.expectJson gotFileMsg uploadRespDecoder
        , timeout = Nothing
        , tracker = Just "upload"
        }
