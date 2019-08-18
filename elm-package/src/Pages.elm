module Pages exposing (Flags, Parser, Program, application)

import Browser
import Browser.Navigation
import Dict exposing (Dict)
import Head
import Html exposing (Html)
import Http
import Json.Decode
import Json.Encode
import Mark
import Pages.Content as Content exposing (Content)
import Pages.ContentCache as ContentCache exposing (ContentCache)
import Pages.Parser exposing (Page)
import Result.Extra
import Task exposing (Task)
import Url exposing (Url)


type alias Content =
    { markdown : List ( List String, { frontMatter : String, body : Maybe String } ), markup : List ( List String, String ) }


type alias Program userFlags userModel userMsg metadata view =
    Platform.Program (Flags userFlags) (Model userModel userMsg metadata view) (Msg userMsg metadata view)


mainView :
    (userModel -> List ( List String, metadata ) -> Page metadata view -> { title : String, body : Html userMsg })
    -> ModelDetails userModel userMsg metadata view
    -> { title : String, body : Html userMsg }
mainView pageView model =
    case model.contentCache of
        Ok site ->
            pageViewOrError pageView model (Ok site)

        -- TODO these lookup helpers should not need it to be a Result
        Err errorView ->
            { title = "Error parsing"
            , body = errorView
            }


pageViewOrError :
    (userModel -> List ( List String, metadata ) -> Page metadata view -> { title : String, body : Html userMsg })
    -> ModelDetails userModel userMsg metadata view
    -> ContentCache userMsg metadata view
    -> { title : String, body : Html userMsg }
pageViewOrError pageView model cache =
    case ContentCache.lookup cache model.url of
        Just entry ->
            case entry of
                ContentCache.Parsed metadata viewList ->
                    pageView model.userModel
                        (ContentCache.extractMetadata cache)
                        { metadata = metadata
                        , view = viewList
                        }

                ContentCache.NeedContent _ ->
                    { title = "Error", body = Html.text "TODO NeedContent" }

                ContentCache.Unparsed _ _ ->
                    { title = "Error", body = Html.text "TODO Unparsed" }

        Nothing ->
            { title = "Page not found"
            , body =
                Html.div []
                    [ Html.text "Page not found. Valid routes:\n\n"
                    , cache
                        |> ContentCache.routesForCache
                        |> String.join ", "
                        |> Html.text
                    ]
            }


view :
    Content
    -> Parser metadata view
    -> (userModel -> List ( List String, metadata ) -> Page metadata view -> { title : String, body : Html userMsg })
    -> ModelDetails userModel userMsg metadata view
    -> Browser.Document (Msg userMsg metadata view)
view content parser pageView model =
    let
        { title, body } =
            mainView pageView model
    in
    { title = title
    , body =
        [ body
            |> Html.map UserMsg
        ]
    }


encodeHeads : List Head.Tag -> Json.Encode.Value
encodeHeads head =
    Json.Encode.list Head.toJson head


type alias Flags userFlags =
    { userFlags
        | imageAssets : Json.Decode.Value
    }


combineTupleResults :
    List ( List String, Result error success )
    -> Result error (List ( List String, success ))
combineTupleResults input =
    input
        |> List.map
            (\( path, result ) ->
                result
                    |> Result.map (\success -> ( path, success ))
            )
        |> Result.Extra.combine


init :
    (String -> view)
    -> Json.Decode.Decoder metadata
    -> (Json.Encode.Value -> Cmd (Msg userMsg metadata view))
    -> (metadata -> List Head.Tag)
    -> Parser metadata view
    -> Content
    -> (Flags userFlags -> ( userModel, Cmd userMsg ))
    -> Flags userFlags
    -> Url
    -> Browser.Navigation.Key
    -> ( ModelDetails userModel userMsg metadata view, Cmd (Msg userMsg metadata view) )
init markdownToHtml frontmatterParser toJsPort head parser content initUserModel flags url key =
    let
        ( userModel, userCmd ) =
            initUserModel flags

        imageAssets =
            Json.Decode.decodeValue
                (Json.Decode.dict Json.Decode.string)
                flags.imageAssets
                |> Result.withDefault Dict.empty

        metadata =
            ContentCache.extractMetadata contentCache

        contentCache =
            ContentCache.init frontmatterParser content parser imageAssets
    in
    case contentCache of
        Ok _ ->
            ( { key = key
              , url = url
              , imageAssets = imageAssets
              , userModel = userModel
              , contentCache = contentCache
              }
            , Cmd.batch
                ([ Content.lookup metadata url
                    |> Maybe.map head
                    |> Maybe.map encodeHeads
                    |> Maybe.map toJsPort
                 , userCmd |> Cmd.map UserMsg |> Just
                 , contentCache
                    |> ContentCache.lazyLoad parser imageAssets markdownToHtml url
                    |> Task.attempt UpdateCache
                    |> Just
                 ]
                    |> List.filterMap identity
                )
            )

        Err error ->
            ( { key = key
              , url = url
              , imageAssets = imageAssets
              , userModel = userModel
              , contentCache = contentCache
              }
            , Cmd.batch
                [ userCmd |> Cmd.map UserMsg
                ]
              -- TODO handle errors better
            )


type Msg userMsg metadata view
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | UserMsg userMsg
    | UpdateCache (Result Http.Error (ContentCache userMsg metadata view))
    | UpdateCacheAndUrl Url (Result Http.Error (ContentCache userMsg metadata view))


type Model userModel userMsg metadata view
    = Model (ModelDetails userModel userMsg metadata view)


type alias ModelDetails userModel userMsg metadata view =
    { key : Browser.Navigation.Key
    , url : Url.Url
    , imageAssets : Dict String String
    , contentCache : ContentCache userMsg metadata view
    , userModel : userModel
    }


update :
    Parser metadata view
    -> (String -> view)
    -> (userMsg -> userModel -> ( userModel, Cmd userMsg ))
    -> Msg userMsg metadata view
    -> ModelDetails userModel userMsg metadata view
    -> ( ModelDetails userModel userMsg metadata view, Cmd (Msg userMsg metadata view) )
update markupParser markdownToHtml userUpdate msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    let
                        navigatingToSamePage =
                            url.path == model.url.path
                    in
                    if navigatingToSamePage then
                        -- this is a workaround for an issue with anchor fragment navigation
                        -- see https://github.com/elm/browser/issues/39
                        ( model, Browser.Navigation.load (Url.toString url) )

                    else
                        ( model, Browser.Navigation.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Browser.Navigation.load href )

        UrlChanged url ->
            ( model
            , model.contentCache
                |> ContentCache.lazyLoad markupParser model.imageAssets markdownToHtml url
                |> Task.attempt (UpdateCacheAndUrl url)
            )

        UserMsg userMsg ->
            let
                ( userModel, userCmd ) =
                    userUpdate userMsg model.userModel
            in
            ( { model | userModel = userModel }, userCmd |> Cmd.map UserMsg )

        UpdateCache cacheUpdateResult ->
            case cacheUpdateResult of
                -- TODO can there be race conditions here? Might need to set something in the model
                -- to keep track of the last url change
                Ok updatedCache ->
                    ( { model | contentCache = updatedCache }, Cmd.none )

                Err _ ->
                    -- TODO handle error
                    ( model, Cmd.none )

        UpdateCacheAndUrl url cacheUpdateResult ->
            case cacheUpdateResult of
                -- TODO can there be race conditions here? Might need to set something in the model
                -- to keep track of the last url change
                Ok updatedCache ->
                    ( { model | url = url, contentCache = updatedCache }, Cmd.none )

                Err _ ->
                    -- TODO handle error
                    ( { model | url = url }, Cmd.none )


type alias Parser metadata view =
    Dict String String
    -> List String
    -> List ( List String, metadata )
    -> Mark.Document (Page metadata view)


application :
    { init : Flags userFlags -> ( userModel, Cmd userMsg )
    , update : userMsg -> userModel -> ( userModel, Cmd userMsg )
    , subscriptions : userModel -> Sub userMsg
    , view : userModel -> List ( List String, metadata ) -> Page metadata view -> { title : String, body : Html userMsg }
    , parser : Parser metadata view
    , content : Content
    , toJsPort : Json.Encode.Value -> Cmd (Msg userMsg metadata view)
    , head : metadata -> List Head.Tag
    , frontmatterParser : Json.Decode.Decoder metadata
    , markdownToHtml : String -> view
    }
    -> Program userFlags userModel userMsg metadata view
application config =
    Browser.application
        { init =
            \flags url key ->
                init config.markdownToHtml config.frontmatterParser config.toJsPort config.head config.parser config.content config.init flags url key
                    |> Tuple.mapFirst Model
        , view = \(Model model) -> view config.content config.parser config.view model
        , update = \msg (Model model) -> update config.parser config.markdownToHtml config.update msg model |> Tuple.mapFirst Model
        , subscriptions =
            \(Model model) ->
                config.subscriptions model.userModel
                    |> Sub.map UserMsg
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
