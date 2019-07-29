module Content exposing (Content, buildAllData, lookup, parseMetadata)

import Dict exposing (Dict)
import Element exposing (Element)
import Index
import List.Extra
import Mark
import Mark.Error
import MarkParser
import MarkupPages.Parser exposing (PageOrPost)
import Metadata exposing (Metadata)
import Result.Extra
import Url exposing (Url)


lookup :
    List ( List String, lookupResult )
    -> Url
    -> Maybe lookupResult
lookup content url =
    List.Extra.find
        (\( path, markup ) ->
            (String.split "/" (url.path |> dropTrailingSlash)
                |> List.drop 1
            )
                == path
        )
        content
        |> Maybe.map Tuple.second


dropTrailingSlash path =
    if path |> String.endsWith "/" then
        String.dropRight 1 path

    else
        path


type alias Content metadata view =
    List ( List String, PageOrPost metadata view )


routes : List ( List String, String ) -> List String
routes record =
    record
        |> List.map Tuple.first
        |> List.map (String.join "/")
        |> List.map (\route -> "/" ++ route)


parseMetadata :
    (Dict String String
     -> List String
     -> List ( List String, metadata )
     -> Mark.Document (PageOrPost metadata view)
    )
    -> Dict String String
    -> List ( List String, String )
    -> Result (Element msg) (List ( List String, metadata ))
parseMetadata parser imageAssets record =
    case
        record
            |> List.map
                (\( path, markup ) ->
                    ( path
                    , Mark.compile
                        (parser imageAssets
                            (routes record)
                            []
                        )
                        markup
                    )
                )
            |> combineResults
    of
        Ok pages ->
            Ok
                (pages
                    |> List.map
                        (Tuple.mapSecond .metadata)
                )

        Err errors ->
            Err (renderErrors errors)


buildAllData :
    List ( List String, metadata )
    ->
        (Dict String String
         -> List String
         -> List ( List String, metadata )
         -> Mark.Document (PageOrPost metadata view)
        )
    -> Dict String String
    -> List ( List String, String )
    -> Result (Element msg) (Content metadata view)
buildAllData metadata parser imageAssets record =
    record
        |> List.map
            (\( path, markup ) ->
                ( path
                , Mark.compile
                    (parser imageAssets
                        (routes record)
                        metadata
                    )
                    markup
                )
            )
        |> combineResults
        |> Result.mapError renderErrors


renderErrors : ( List String, List Mark.Error.Error ) -> Element msg
renderErrors ( path, errors ) =
    Element.column []
        [ Element.text (path |> String.join "/")
        , errors
            |> List.map (Mark.Error.toHtml Mark.Error.Light)
            |> List.map Element.html
            |> Element.column []
        ]


combineResults :
    List ( List String, Mark.Outcome (List Mark.Error.Error) (Mark.Partial (PageOrPost metadata view)) (PageOrPost metadata view) )
    -> Result ( List String, List Mark.Error.Error ) (List ( List String, PageOrPost metadata view ))
combineResults list =
    list
        |> List.map
            (\( path, outcome ) ->
                case outcome of
                    Mark.Success parsedMarkup ->
                        Ok ( path, parsedMarkup )

                    Mark.Almost partial ->
                        -- Err "Almost"
                        Err ( path, partial.errors )

                    Mark.Failure failures ->
                        Err ( path, failures )
            )
        |> Result.Extra.combine
