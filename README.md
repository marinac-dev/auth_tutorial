# IMPORTANT: This tutorial is still "viable" but I would strongly suggest usage of [this](https://hexdocs.pm/phx_gen_auth/overview.html) instead

# Tutorial

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

# Auth tutorial for setting up basic user auth with `put_session()`

## Deps used

```bash
# Admin auth
{:basic_auth, "~> 2.2.2"},
# Password hashing
{:bcrypt_elixir, "~> 2.0"}
```

## Setup

Start off by running `mix deps.get`

### User Schema

Make sure that you have some context that is like `Accounts.User` with `email:unique` and `password_hash` and that you have `Accounts` module with `get_user!(id)`... etc.

You can do this with

```bash
terminal:~/tutorial/$ mix phx.gen.html Accounts User users email:string:unique password_hash:string
```

Add `resources "/users", UserController, singleton: true` to the `router.ex`

### Password hashing

After that open up `accounts/user.ex` and add line bellow to `changeset()`

```elixir
def changeset(user, attrs) do
  ...
  |> update_change(:password_hash, &Bcrypt.hash_pwd_salt/1)
end
```

### Auth helper

In `/tutorial_web/` create folder `/helpers` and create file `auth.ex`

```elixir
defmodule TutorialWeb.Helpers.Auth do
  import Plug.Conn, only: [get_session: 2]
  alias Tutorial.{Repo, Accounts.User}

  def signed_in?(conn) do
    user_id = get_session(conn, :current_user_id)
    if user_id, do: !!Repo.get(User, user_id)
  end
end
```

Then open your `tutorial_web.ex` and inside add this `import`, we are doing this because we want to have this function in every `view`

```elixir
def view do
  quote do
    ...
    import TutorialWeb.Helpers.Auth, only: [signed_in?: 1]
  end
end
```

### Session templates/view/router/controller

#### Templates

Create `/session` folder in `/templates` and inside create 2 files `sign-in.html.eex` and `sign-up.html.eex`
One will be used for Signing in and the other for Signing out

###### /session/sign-in.html

```elixir
<%= form_for @conn, Routes.session_path(@conn, :create_session),[as: :session] , fn f -> %>

  <%= label f, :email %>
  <%= text_input f, :email %>
  <%= error_tag f, :email %>

  <%= label f, :password %>
  <%= password_input f, :password_hash %>
  <%= error_tag f, :password_hash %>

  <div>
    <%= submit "Sign in" %>
  </div>
<% end %>

```

###### /session/sign-up.html

```elixir
<%= form_for @changeset, Routes.session_path(@conn, :create_user) , fn f -> %>
  <%= if @changeset.action do %>
    <div class="alert alert-danger">
      <p>Oops, something went wrong! Please check the errors below.</p>
    </div>
  <% end %>

  <%= label f, :email %>
  <%= text_input f, :email %>
  <%= error_tag f, :email %>

  <%= label f, :password %>
  <%= password_input f, :password_hash %>
  <%= error_tag f, :password_hash %>

  <div>
    <%= submit "Sign up" %>
  </div>
<% end %>

```

#### Views

Create `session_view.ex` in `/views` folder 

```elixir
defmodule TutorialWeb.SessionView do
  use TutorialWeb, :view
end
```

#### Router

under you  `scope "/"` add following

```elixir
scope "/", TutorialWeb do
  pipe_through :browser
  ...
  # Sign in
  get "/sign-in", SessionController, :sign_in
  post"/sign-in", SessionController, :create_session

  # Sign up
  get "/sign-up", SessionController, :sign_up
  post"/sign-up", SessionController, :create_user

  # Sign out
  post "/sign-out", SessionController, :sign_out
end
```

#### Controller

Create `session_controller.ex` in `/controllers`

```elixir
defmodule TutorialWeb.SessionController do
  use TutorialWeb, :controller

  alias Tutorial.Accounts
  alias Accounts.User

  def sign_in(conn, _params) do
    # If user is logged in and tries to connecto to "/sign-in" redirect him
    if is_logged?(conn) do
      redirect(conn, to: Routes.user_path(conn, :show))
    else
      render(conn, "sign-in.html")
    end
  end

  def sign_up(conn, _params) do
    # If user is logged in and tries to connecto to "/sign-up" redirect him
    if is_logged?(conn) do
      redirect(conn, to: Routes.user_path(conn, :show))
    else
      changeset = Accounts.change_user(%User{})
      render(conn, "sign-up.html", changeset: changeset)
    end
  end

  defp is_logged?(conn), do: !!get_session(conn, :current_user_id)

  def create_session(conn, %{"session" => auth_params} = _params) do
    user = Accounts.get_by_email(auth_params["email"])

    case Bcrypt.check_pass(user, auth_params["password_hash"]) do
      {:ok, user} ->
        conn
        |> put_session(:current_user_id, user.id)
        |> put_flash(:info, "Sign in, successful!")
        |> redirect(to: Routes.user_path(conn, :show))

      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid e-mail/password. Try again!")
        |> redirect(to: Routes.session_path(conn, :sign_in))
    end
  end

  def create_user(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:current_user_id, user.id)
        |> put_flash(:info, "Sign up, successful!")
        |> redirect(to: Routes.user_path(conn, :show))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "sign-up.html", changeset: changeset)
    end
  end

  def sign_out(conn, _params) do
    conn
    |> delete_session(:current_user_id)
    |> put_flash(:info, "Signed out.")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end

```

#### Update `accounts.ex`

Remember when we wrote `user = Accounts.get_by_email(auth_params["email"])` we need to define that fn
Open `accounts.ex` and add this fn after `get_user!(id)`

```elixir
  def get_by_email(nil), do: nil

  def get_by_email(email), do: User |> Repo.get_by(email: email)
```

**NOTE** We will use advantage of pattern matching and create two fn-s just in case we get `nil`

#### Update `user_controller.ex`

##### Part 1 (update params)

In `UserController` `show`, `edit`, `update` and `delete` second param is trying to pattern match for `%{"id" => id}` but since we are going to get user data from `conn.asssigns.current_user` go ahead and replace `%{"id" => id}` with `_params`

```elixir
def FN(conn, %{"id" => id}) do
  ...
end
# CHANGE TO
def FN(conn, _params) do
  ...
end
```

*Do that for all 4 of them*

##### Part 2 (update user data)

We are still in `UserController` and fn's `show`, `edit`, `update` and `delete` are using that `id` that we just removed, to obtain user data. We are going to change that now

```elixir
# Change
user = Accounts.get_user!(id)
# Into
user = conn.assigns.current_user
```

### Set `conn.assigns.current_user`

Now we need to assign `current_user` to `@conn`. But how?
Read more to find out. :)

#### Setting up Auth Plug

You remember that `/helpers` folder that we created earlier? Open it and create new file inside, called `plug_auth.ex` and put this code inside.

```elixir
defmodule TutorialWeb.Helpers.AuthGuest do
  import Plug.Conn
  import Phoenix.Controller
  alias Tutorial.Accounts

  def init(default), do: default

  def call(conn, _opts) do
    user_id = get_session(conn, :current_user_id)
    auth_reply(conn, user_id)
  end

  defp auth_reply(conn, nil) do
    conn
    |> put_flash(:error, "You have to sign in first!")
    |> redirect(to: "/sign-in")
    |> halt()
  end

  defp auth_reply(conn, user_id) do
    user = Accounts.get_user!(user_id)

    conn
    |> assign(:current_user, user)
  end
end
```

After that add this code into your `router.ex`

```elixir
  pipeline :auth do
    plug TutorialWeb.Helpers.AuthGuest
  end
```

And add that pipeline in `pipe_through` for scope you want to require logged user
For example:

```elixir
scope "/", TutorialWeb do
  pipe_through [:browser, :auth]
  resources "/users", UserController, singleton: true
end
```

## Templates update /users/ && add Sign-in and Sign-out links

### User template

After adding all of this, few things need to be considered.

* `singleton: true`
  * We don't want our user to have acces to the list of **ALL USERS** so we need to remove links that point `to: Routes.user_path(@conn, :index)`.
  Lets give that power only to admin.

* UserController fn-s `new` and `create`
  * Again we don't want our user to be able to use these functions that are pre-generated by
  `mix phx.gen.html` so we should delete those **files**, **controller functions** and **limit**
  them in `router.ex`. Update existing resources tag with following.
  `resources "/users", UserController, only: [:show, :edit, :update], singleton: true`

* Update UserController fn's with redirect
  * Some fn's where you redirect to path that doesn't take user as params
  but you still pass it because of `mix phx.gen.html`. You just need to
  remove that user.

And finally lets open `/layout/app.html.eex` and add following

```elixir
<%= if signed_in?(@conn) do %>
  <%= link "Sign out", to: Routes.session_path(@conn, :sign_out), method: :post %>
<% else %>
  <%= link "Sign in", to: Routes.session_path(@conn, :sign_in), method: :get %>
  |
  <%= link "Sign up", to: Routes.session_path(@conn, :sign_up), method: :get %>
<% end %>
```

****

## mix phx.server

Yep you read it, just run your app now and it should most of it gucci. :)
*except the `html.eex` files that you didn't change* :P

****
