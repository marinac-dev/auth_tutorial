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