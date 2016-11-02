module MJournal exposing (..)

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import String

type alias Model =
    { entries : List String
    , signInEmail : String
    , signInPassword : String
    , enableSignIn : Bool
    }


model : Model
model =
    { entries = []
    , signInEmail = ""
    , signInPassword = ""
    , enableSignIn = False
    }


type Message
    = InputEmail String
    | InputPassword String
    | SignInStop


view : Model -> Html Message
view model =
    div []
        [ h1
            [ class "app-name" ]
            [ a
                [ href "/" ]
                [ text "mjournal" ]
            ]
        , h2
            [ class "app-tag" ]
            [ text "minimalist journaling" ]
        , div
            [ class "sign-in" ]
            [ div
                [ class "error" ]
                []
            , Html.form
                []
                -- data-ng-submit "signIn($event)"
                [ label
                    []
                    [ text "email" ]
                , input
                    [ type' "email", placeholder "you@example.com", onInput InputEmail ]
                    []
                , label
                    []
                    [ text "password" ]
                , input
                    [ type' "password", onInput InputPassword ]
                    -- ng-model "password", class "ng-pristine ng-valid"
                    []
                , input
                    [ type' "submit", class "signIn", value "Sign In", disabled (not model.enableSignIn) ]
                    -- ng-disabled "!(email && password)",
                    []
                , input
                    [ type' "submit", class "register", value "Register", disabled (not model.enableSignIn) ]
                    -- ng-click "signIn($event, true)", ng-disabled "!(email && password)"
                    []
                ]
            , div
                [ class "about" ]
                [ h3
                    []
                    [ text "mjournal is a clean, organized journal for notes and thoughts" ]
                , ul
                    []
                    [ li
                        []
                        [ text "uncluttered design lets you focus on your words" ]
                    , li
                        []
                        [ text "Entries are automatically timestamped and displayed chronologically" ]
                    , li
                        []
                        [ text "Use tags as a simple way to categorize related entries" ]
                    , li
                        []
                        [ text "Powerful full-text search lets you find entries quickly" ]
                    ]
                ]
            ]
        ]



-- setSignInFormEmail : { b | email : a } -> c -> { b | email : c }
-- setSignInFormEmail signInForm email =
--     { signInForm | email = email }
--
--
-- setSignInForm {signInForm} email =
--     {signInForm | email = email}

noEmpties : List String -> Bool
noEmpties strings =
    List.all (\x -> not (String.isEmpty x)) strings

update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        InputEmail newEmail ->
            ( { model | signInEmail = newEmail, enableSignIn = (noEmpties [newEmail, model.signInPassword]) }, Cmd.none )

        InputPassword newPassword ->
            ( { model | signInPassword = newPassword, enableSignIn = (noEmpties [model.signInEmail, newPassword])  }, Cmd.none )

        SignInStop ->
            ( model, Cmd.none )


main : Program Never
main =
    Html.App.program
        { init = ( model, Cmd.none )
        , view = view
        , update = update
        , subscriptions = (\model -> Sub.none)
        }
