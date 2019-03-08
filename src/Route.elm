module Route exposing (Route(..), parse, title, toUrl)

import Page
import Url.Builder
import Url.Parser exposing ((</>), Parser, s)
import View.MenuBar


type Route
    = HomeOld
    | Home
    | Coaches
    | Events
    | Learn (Maybe String)
    | Intros
    | CaseStudies
    | Contact
    | Signup { maybeReferenceId : Maybe String }
    | Feedback
    | CustomPage Page.Page


toUrl route =
    (case route of
        Home ->
            []

        HomeOld ->
            []

        Coaches ->
            [ "coaches" ]

        Intros ->
            [ "intro" ]

        Learn maybeLearnTitle ->
            case maybeLearnTitle of
                Just learnTitle ->
                    [ "learn", learnTitle ]

                Nothing ->
                    [ "learn" ]

        CaseStudies ->
            [ "case-studies" ]

        Contact ->
            [ "contact" ]

        Signup _ ->
            [ "signup" ]

        Feedback ->
            [ "feedback" ]

        Events ->
            [ "events" ]

        CustomPage page ->
            [ page.url ]
    )
        |> (\path -> Url.Builder.absolute path [])


title : Maybe Route -> String
title maybeRoute =
    maybeRoute
        |> Maybe.map
            (\route ->
                case route of
                    Home ->
                        "Incremental Elm Consulting"

                    HomeOld ->
                        "Incremental Elm Consulting"

                    Coaches ->
                        "Incremental Elm Coaches"

                    Intros ->
                        "Free Intro Talk"

                    Learn maybeLearnTitle ->
                        case maybeLearnTitle of
                            Just learnTitle ->
                                learnTitle

                            Nothing ->
                                "Incremental Elm Learning Resources"

                    CaseStudies ->
                        "Incremental Elm Case Studies"

                    Contact ->
                        "Contact Incremental Elm"

                    Signup _ ->
                        "Incremental Elm - Signup"

                    Feedback ->
                        "Incremental Elm Workshop Feedback"

                    Events ->
                        "Incremental Elm - Event Calendar"

                    CustomPage page ->
                        page.title
            )
        |> Maybe.withDefault "Incremental Elm - Page not found"


parse url =
    url
        |> Url.Parser.parse parser


parser : Url.Parser.Parser (Route -> a) a
parser =
    Url.Parser.oneOf
        [ Url.Parser.map HomeOld Url.Parser.top
        , Url.Parser.map Home (s "new")
        , Url.Parser.map Intros (s "intro")
        , Url.Parser.map Events (s "events")
        , Url.Parser.map Feedback (s "feedback")
        , Url.Parser.map Coaches (s "coaches")
        , Url.Parser.map Contact (s "contact")
        , Url.Parser.map CaseStudies (s "case-studies")
        , Url.Parser.map (\learnPostName -> Learn (Just learnPostName)) (s "learn" </> Url.Parser.string)
        , Url.Parser.map (Learn Nothing) (s "learn")
        , Url.Parser.map (Signup { maybeReferenceId = Nothing }) (s "signup")
        , Url.Parser.map (\signupPath -> Signup { maybeReferenceId = Nothing }) (s "signup" </> Url.Parser.string)
        , Url.Parser.map (\signupPath referenceId -> Signup { maybeReferenceId = Just referenceId }) (s "signup" </> Url.Parser.string </> Url.Parser.string)
        , customParser
        ]


customParser : Url.Parser.Parser (Route -> a) a
customParser =
    Page.all
        |> List.map
            (\page ->
                Url.Parser.map (CustomPage page) (s page.url)
            )
        |> Url.Parser.oneOf
