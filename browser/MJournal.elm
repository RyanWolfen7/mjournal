port module MJournal exposing (main)

import About exposing (about)
import Entries
import EntriesView
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Location
import Menu
import Messages exposing (Msg(..))
import Model exposing (Model, Theme, Flags, Screen(..))
import Navigation
import Pagination
import SignIn
import Theme


port clickDocument : (Bool -> msg) -> Sub msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        InputEmail newEmail ->
            ( { model | signInEmail = newEmail, signInError = "" }, Cmd.none )

        InputPassword newPassword ->
            ( { model | signInPassword = newPassword, signInError = "" }, Cmd.none )

        SignIn ->
            ( { model | signInError = "" }, SignIn.signIn model.signInEmail model.signInPassword )

        SignInDone (Ok user) ->
            let
                oldPageState =
                    model.pageState

                newPageState =
                    { oldPageState | screen = Model.EntriesScreen Nothing Nothing Nothing }
            in
                ( { model
                    | pageState = newPageState
                    , signInError = ""
                    , theme = user.theme
                  }
                , Cmd.batch
                    [ (Theme.setTheme (Theme.toString user.theme))
                    , (Entries.getEntries Nothing)
                    ]
                )

        SignInDone (Err error) ->
            SignIn.signInDone model error

        Register ->
            ( { model | signInError = "" }, SignIn.register model.signInEmail model.signInPassword )

        NextPage ->
            Entries.nextPage model

        PreviousPage ->
            Entries.previousPage model

        -- NextPage ->
        --     ( { model | direction = Just Model.Next }, Entries.nextPage model )
        --
        -- PreviousPage ->
        --     ( { model | direction = Just Model.Previous }, Entries.previousPage model )
        CreateEntry s ->
            ( model, Entries.create model.newEntry )

        CreateEntryDone (Ok entry) ->
            ( { model
                | entries = List.append model.entries [ entry ]
                , newEntry = Entries.new
              }
            , Cmd.none
            )

        CreateEntryDone (Err message) ->
            ( model, Cmd.none )

        DeleteEntry1 entry ->
            case entry.confirmingDelete of
                True ->
                    let
                        newModel =
                            { model | entries = List.filter (\e -> not (e.id == entry.id)) model.entries }
                    in
                        ( newModel, Entries.delete2 entry )

                False ->
                    let
                        newModel =
                            Entries.delete1 model entry
                    in
                        ( newModel, Cmd.none )

        DeleteEntryDone (Ok ()) ->
            ( model, Cmd.none )

        DeleteEntryDone (Err message) ->
            ( model, Cmd.none )

        GetEntriesDone (Ok entries) ->
            ( { model | entries = entries }, Cmd.none )

        GetEntriesDone (Err error) ->
            ( model, Cmd.none )

        CloseMenu ->
            ( { model | menuOpen = False }, Cmd.none )

        ToggleMenu _ ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        SetTheme theme ->
            ( { model | theme = theme }, Theme.set theme )

        SetThemeDone _ ->
            ( model, Theme.setTheme (Theme.toString model.theme) )

        SetNewEntryBody newBody ->
            let
                entry1 =
                    model.newEntry

                entry2 =
                    { entry1 | body = newBody }

                newModel =
                    { model | newEntry = entry2 }
            in
                ( newModel, Cmd.none )

        SetNewEntryBodyAndSave newBody ->
            let
                entry1 =
                    model.newEntry

                entry2 =
                    { entry1 | body = newBody }

                newModel =
                    { model | newEntry = Entries.new }
            in
                ( newModel, Entries.create entry2 )

        SaveBody entry newBody ->
            Entries.saveBody model entry newBody

        SaveBodyDone (Ok _) ->
            ( model, Cmd.none )

        SaveBodyDone (Err _) ->
            ( model, Cmd.none )

        SetTextSearch textSearch ->
            Entries.setTextSearch model textSearch

        Search ->
            let
                oldPageState =
                    model.pageState

                newPageState =
                    { oldPageState | after = Nothing, before = Nothing }

                newModel =
                    { model | pageState = newPageState }
            in
                ( newModel, Navigation.newUrl (Location.location newModel) )

        SearchDone (Ok entries) ->
            ( { model | entries = entries }, Cmd.none )

        SearchDone (Err message) ->
            ( model, Cmd.none )

        ClearTextSearch ->
            Entries.clearTextSearch model

        ChangeUrl location ->
            route model location

        InputNewTag entry tag ->
            ( Entries.editNewTag model entry tag, Cmd.none )

        AddTag entry ->
            Entries.addTag model entry

        SaveTagsDone (Ok _) ->
            ( model, Cmd.none )

        SaveTagsDone (Err _) ->
            ( model, Cmd.none )

        DeleteTag entry tag ->
            Entries.deleteTag model entry tag

        DeleteTagDone (Ok _) ->
            ( model, Cmd.none )

        DeleteTagDone (Err _) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    clickDocument (\x -> CloseMenu)


view : Model -> Html Msg
view model =
    case model.pageState.screen of
        Model.SignInScreen ->
            div [ onClick CloseMenu ]
                [ h1 [ class "app-name" ] [ a [ href "/" ] [ text "mjournal" ] ]
                , h2 [ class "app-tag" ] [ text "minimalist journaling" ]
                , SignIn.signInDiv model
                , about
                ]

        Model.EntriesScreen textSearch after before ->
            div [ onClick CloseMenu ]
                [ h1 [ class "app-name" ]
                    [ a [ href "/" ] [ text "mjournal" ]
                    ]
                , h2 [ class "app-tag" ] [ text "minimalist journaling" ]
                , Menu.component model
                , div [ class "entries" ]
                    [ Pagination.toolbar model
                    ]
                , div [ class "notebook" ]
                    [ div [ class "page" ]
                        [ EntriesView.list model
                        ]
                    , EntriesView.new model
                    ]
                ]



-- Use this version for elm-reactor
-- init: ( Model, Cmd Msg)
-- init =
--   let flags = Flags Nothing Nothing
--   in
--     initFlags flags
--
-- main : Program Never Model Msg
-- main =
--     Html.program
--         { init = init
--         , view = view
--         , update = update
--         , subscriptions = subscriptions
--         }
-- Use this version for regular deploys


route : Model -> Navigation.Location -> ( Model, Cmd Msg )
route model location =
    let
        newModel =
            { model | pageState = Location.parse model.pageState location }

        cmd =
            case newModel.pageState.screen of
                Model.EntriesScreen textSearch after before ->
                    Entries.search textSearch after before

                Model.SignInScreen ->
                    Cmd.none
    in
        ( newModel, cmd )


initFlags : Flags -> Navigation.Location -> ( Model, Cmd Msg )
initFlags flags location =
    let
        theme =
            case flags.theme of
                Just name ->
                    Theme.parse name

                Nothing ->
                    Model.Moleskine

        pageState =
            Location.parse (Pagination.init flags location) location

        model =
            { entries = []
            , newEntry = Entries.new
            , menuOpen = False
            , pageState = pageState
            , signInEmail = "1@example.com"
            , signInError = ""
            , signInPassword = "password"
            , theme = theme
            }
    in
        route model location


main : Program Flags Model Msg
main =
    Navigation.programWithFlags ChangeUrl
        { init = initFlags
        , view = view
        , update = update
        , subscriptions = subscriptions
        }