defmodule TutorialWeb.Helpers.Auth do
  import Plug.Conn, only: [get_session: 2]
  alias Tutorial.{Repo, Accounts.User}

  def signed_in?(conn) do
    user_id = get_session(conn, :current_user_id)
    if user_id, do: !!Repo.get(User, user_id)
  end
end
