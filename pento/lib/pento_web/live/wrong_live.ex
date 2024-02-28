defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  def mount(_params, session, socket) do
    {
      :ok,
      assign(
        socket,
        score: 0,
        message: "Guess a number.",
        current_number: generate_number(),
        user: Pento.Accounts.get_user_by_session_token(session["user_token"]),
        session_id: session["live_socket_id"]
      )
    }
  end

  def render(assigns) do
    ~L"""
    <h1>Your score: <%= @score %></h1>
    <h2>
      <%= @message %>
      It's <%= time() %>
    </h2>
    <h2>
      <%= for n <- 1..10 do %>
        <a href="#" phx-click="guess" phx-value-number="<%= n %>"><%= n %></a>
      <% end %>
    </h2>
    <pre>
      <%= @user.email %>
      <%= @session_id %>
    </pre>

    """
  end

  def time() do
    DateTime.utc_now() |> to_string()
  end

  def generate_number() do
    Enum.random(1..10)
  end

  def handle_event("guess", %{"number" => guess} = data, socket) do

    {message, score} =
    if (String.to_integer(guess) == socket.assigns.current_number) do
      {
        "You Win!!!",
        socket.assigns.score + 1
      }
    else
      {
        "Your guess: #{guess}. Wrong. Guess again. ",
        socket.assigns.score - 1
      }
    end

    {
      :noreply,
      assign(
        socket,
        message: message,
        score: score,
        current_number: generate_number()
      )
    }
  end
end
