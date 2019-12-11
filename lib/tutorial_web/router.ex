defmodule TutorialWeb.Router do
  use TutorialWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug TutorialWeb.Helpers.AuthGuest
  end

  scope "/", TutorialWeb do
    pipe_through :browser

    get "/", PageController, :index

    # Sign in
    get "/sign-in", SessionController, :sign_in
    post "/sign-in", SessionController, :create_session

    # Sign up
    get "/sign-up", SessionController, :sign_up
    post "/sign-up", SessionController, :create_user

    # Sign out
    post "/sign-out", SessionController, :sign_out
    
  end

  scope "/", TutorialWeb do
    pipe_through [:browser, :auth]
    resources "/users", UserController, only: [:show, :edit, :update], singleton: true
    
  end

  # Other scopes may use custom stacks.
  # scope "/api", TutorialWeb do
  #   pipe_through :api
  # end
end
