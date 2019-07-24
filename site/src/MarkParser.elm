module MarkParser exposing (Metadata, document)

import Element exposing (Element)
import Element.Border
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes as Attr
import Mark
import Mark.Error
import View.DripSignupForm


document :
    Element msg
    ->
        Mark.Document
            { body : List (Element msg)
            , metadata : Metadata msg
            }
document indexView =
    Mark.documentWith
        (\meta body ->
            { metadata = meta
            , body =
                [ Element.textColumn
                    [ Element.centerX
                    , Element.spacing 20
                    , Element.width Element.fill
                    , Element.padding 50
                    ]
                    (titleView meta.title.styled
                        :: body
                    )
                ]
            }
        )
        -- We have some required metadata that starts our document.
        { metadata = metadata
        , body =
            Mark.manyOf
                [ header
                , h2
                , image
                , list
                , code
                , indexContent indexView
                , signupForm
                , Mark.map
                    (Element.paragraph
                        []
                    )
                    text
                ]
        }


titleView : Element msg -> Element msg
titleView title =
    Element.paragraph
        [ Font.size 56
        , Font.center
        , Font.family [ Font.typeface "Raleway" ]
        , Font.bold
        ]
        [ Element.el
            [ Element.centerX
            , Element.width Element.shrink
            ]
            title
        ]



{- Handle Text -}


text : Mark.Block (List (Element msg))
text =
    Mark.textWith
        { view =
            \styles string ->
                viewText styles string
        , replacements = Mark.commonReplacements
        , inlines =
            [ Mark.annotation "link"
                (\texts url ->
                    Element.link []
                        { url = url
                        , label =
                            Element.row [ Element.htmlAttribute (Attr.style "display" "inline-flex") ]
                                (List.map (applyTuple viewText) texts)
                        }
                )
                |> Mark.field "url" Mark.string
            , Mark.verbatim "code"
                (\str ->
                    Element.el [ Font.color (Element.rgb255 200 50 50) ] (Element.text str)
                )
            ]
        }


titleText : Mark.Block (List { styled : Element msg, raw : String })
titleText =
    Mark.textWith
        { view =
            \styles string ->
                { styled = viewText styles string
                , raw = string
                }
        , replacements = Mark.commonReplacements
        , inlines =
            [-- Mark.annotation "link"
             --    (\texts url ->
             --        Element.link []
             --            { url = url
             --            , label =
             --                Element.row
             --                    [ Element.htmlAttribute (Attr.style "display" "inline-flex")
             --                    ]
             --                    (List.map (applyTuple viewText) texts)
             --            }
             --    )
             --    |> Mark.field "url" Mark.string
            ]
        }


{-| Render a text fragment.
-}



-- textFragment : Mark.Text -> model -> Element msg
-- textFragment node model_ =
--     case node of
--         Mark.Text styles txt ->
--             Element.el (List.concatMap toStyles styles) (Element.text txt)


applyTuple : (a -> b -> c) -> ( a, b ) -> c
applyTuple fn ( one, two ) =
    fn one two


viewText : { a | bold : Bool, italic : Bool, strike : Bool } -> String -> Element msg
viewText styles string =
    Element.el (stylesFor styles) (Element.text string)


stylesFor : { a | bold : Bool, italic : Bool, strike : Bool } -> List (Element.Attribute b)
stylesFor styles =
    [ if styles.bold then
        Just Font.bold

      else
        Nothing
    , if styles.italic then
        Just Font.italic

      else
        Nothing
    , if styles.strike then
        Just Font.strike

      else
        Nothing
    ]
        |> List.filterMap identity



{- Handle Metadata -}


type alias Metadata msg =
    { author : String
    , description : List (Element msg)
    , tags : List String
    , title : { styled : Element msg, raw : String }
    }


metadata : Mark.Block (Metadata msg)
metadata =
    Mark.record "Article"
        (\author description title tags ->
            { author = author
            , description = description
            , title = title
            , tags = tags
            }
        )
        |> Mark.field "author" Mark.string
        |> Mark.field "description" text
        |> Mark.field "title"
            (Mark.map
                gather
                titleText
            )
        |> Mark.field "tags" (Mark.string |> Mark.map (String.split " "))
        |> Mark.toBlock


gather : List { styled : Element msg, raw : String } -> { styled : Element msg, raw : String }
gather myList =
    let
        styled =
            myList
                |> List.map .styled
                |> Element.paragraph []

        raw =
            myList
                |> List.map .raw
                |> String.join " "
    in
    { styled = styled, raw = raw }



{- Handle Blocks -}


header : Mark.Block (Element msg)
header =
    Mark.block "H1"
        (\children ->
            Element.paragraph
                [ Font.size 24
                , Font.semiBold
                , Font.center
                , Font.family [ Font.typeface "Raleway" ]
                ]
                children
        )
        text


h2 : Mark.Block (Element msg)
h2 =
    Mark.block "H2"
        (\children ->
            Element.paragraph
                [ Font.size 18
                , Font.semiBold
                , Font.alignLeft
                , Font.family [ Font.typeface "Raleway" ]
                ]
                children
        )
        text


image : Mark.Block (Element msg)
image =
    Mark.record "Image"
        (\src description ->
            Element.image
                [ Element.width (Element.fill |> Element.maximum 600)
                , Element.centerX
                ]
                { src = src
                , description = description
                }
                |> Element.el [ Element.centerX ]
        )
        |> Mark.field "src" Mark.string
        |> Mark.field "description" Mark.string
        |> Mark.toBlock


indexContent : Element msg -> Mark.Block (Element msg)
indexContent content =
    Mark.record "IndexContent"
        (\postsPath ->
            content
        )
        |> Mark.field "posts"
            (Mark.string
                |> Mark.verify
                    (\postDirectory ->
                        if postDirectory == "articles" then
                            Ok "articles"

                        else
                            Err
                                { title = "Could not find posts path `" ++ postDirectory ++ "`"
                                , message = "Must be one of " :: [ "articles" ]
                                }
                    )
            )
        |> Mark.toBlock


code : Mark.Block (Element msg)
code =
    Mark.block "Code"
        (\str ->
            Html.pre
                [ Attr.style "padding" "12px"
                , Attr.style "background-color" "#eee"
                ]
                [ Html.text str ]
                |> Element.html
         -- TODO
        )
        Mark.string



{- Handling bulleted and numbered lists -}


list : Mark.Block (Element msg)
list =
    Mark.tree "List" renderList (Mark.map (Element.paragraph []) text)



-- Note: we have to define this as a separate function because
-- `Items` and `Node` are a pair of mutually recursive data structures.
-- It's easiest to render them using two separate functions:
-- renderList and renderItem


renderList : Mark.Enumerated (Element msg) -> Element msg
renderList (Mark.Enumerated enum) =
    let
        group =
            case enum.icon of
                Mark.Bullet ->
                    Html.ul

                Mark.Number ->
                    Html.ol
    in
    -- group []
    --     (List.map renderItem enum.items)
    Element.column []
        (List.map renderItem enum.items)


renderItem : Mark.Item (Element msg) -> Element msg
renderItem (Mark.Item item) =
    -- Html.li []
    --     [ Html.div [] item.content
    --     , renderList item.children
    --     ]
    Element.textColumn []
        [ Element.row [ Element.spacing 10 ]
            [ Element.el [] (Element.text "•")
            , Element.paragraph [] item.content
            ]
        , renderList item.children
        ]


signupForm : Mark.Block (Element msg)
signupForm =
    let
        body =
            [ Element.none ]
    in
    Mark.record "Signup"
        (\buttonText formId ->
            [ Element.column
                [ Font.center
                , Element.spacing 30
                , Element.centerX
                ]
                body
            , View.DripSignupForm.viewNew buttonText formId { maybeReferenceId = Nothing }
                |> Element.html
                |> Element.el [ Element.width Element.fill ]
            , [ Element.text "We'll never share your email. Unsubscribe any time." ]
                |> Element.paragraph
                    [ Font.color (Element.rgba255 0 0 0 0.5)
                    , Font.size 14
                    , Font.center
                    ]
            ]
                |> Element.column
                    [ Element.width Element.fill
                    , Element.padding 20
                    , Element.spacing 20
                    , Element.Border.shadow { offset = ( 0, 0 ), size = 1, blur = 4, color = Element.rgb 0.8 0.8 0.8 }
                    , Element.mouseOver
                        [ Element.Border.shadow { offset = ( 0, 0 ), size = 1, blur = 4, color = Element.rgb 0.85 0.85 0.85 } ]
                    , Element.width (Element.fill |> Element.maximum 500)
                    , Element.centerX
                    ]
                |> Element.el []
        )
        |> Mark.field "buttonText" Mark.string
        |> Mark.field "formId" Mark.string
        |> Mark.toBlock



-- (Mark.manyOf
--     [ header
--     , list
--
--     -- , topLevel
--     ]
-- )
-- Mark.record "Article"
--     (\author description title tags ->
--         { author = author
--         , description = description
--         , title = title
--         , tags = tags
--         }
--     )
--     |> Mark.field "author" Mark.string
--     |> Mark.field "description" text
--     |> Mark.field "title"
--         (Mark.map
--             gather
--             titleText
--         )
--     |> Mark.field "tags" (Mark.string |> Mark.map (String.split " "))
--     |> Mark.toBlock
