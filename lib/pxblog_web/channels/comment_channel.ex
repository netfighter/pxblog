defmodule PxblogWeb.CommentChannel do
  use Pxblog.Web, :channel
  alias PxblogWeb.CommentHelper
  alias Pxblog.Repo
  alias Pxblog.User
  alias Pxblog.Comment
  import Canada.Can, only: [can?: 3]

  def join("comments:" <> _comment_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (comments:lobby).
  def handle_in("CREATED_COMMENT", payload, socket) do
    case CommentHelper.create(payload, socket) do
      {:ok, comment} ->
        broadcast(
          socket,
          "CREATED_COMMENT",
          Map.merge(
            payload,
            %{
              commentId: comment.id,
              insertedAt: comment.inserted_at,
              authorId: comment.author_id,
              author: comment.author
            }
          )
        )
        {:noreply, socket}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  # Intercept CREATED_COMMENT and check delete permission for every receiver
  intercept ["CREATED_COMMENT"]
  def handle_out("CREATED_COMMENT", payload, socket) do
    user_id = if is_nil(socket.assigns[:user]), do: 0, else: socket.assigns[:user]
    user = Repo.one from u in User, where: u.id == ^user_id, preload: [:role]
    if user do
      comment = %Comment{id: payload.commentId, user_id: payload.authorId}
      push(
        socket,
        "CREATED_COMMENT",
        Map.merge(
          payload,
          %{allowedToDelete: user |> can?(:delete, comment) }
        )
      )
    else
      push socket, "CREATED_COMMENT", payload
    end
    {:noreply, socket}
  end

  def handle_in("DELETED_COMMENT", payload, socket) do
    case CommentHelper.delete(payload, socket) do
      {:ok, _} ->
        broadcast socket, "DELETED_COMMENT", payload
        {:noreply, socket}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
