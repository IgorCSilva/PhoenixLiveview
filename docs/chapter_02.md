# Phoenix and Authentication

## Generate The Authentication Layer

### Run the Generator
Inside the Pento application run:
`mix phx.gen.auth Accounts User users`

  Do you want to create a LiveView based authentication system? [Yn] Y

Download generated dependencies.
`mix deps.get`

Run migrations
`mix ecto.migrate`

Now, run the tests and verify that they are all ok:
`mix test`

## Explore Accounts from IEx

### Create a Valid User

```sh
iex(3)> params = %{email: "mercutio@grox.io", password: "R0sesBy0therNames"}

iex(4)> Accounts.register_user(params)

{:ok,
 #Pento.Accounts.User<
   __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
   id: 1,
   email: "mercutio@grox.io",
   confirmed_at: nil,
   inserted_at: ~N[2024-02-22 21:18:04],
   updated_at: ~N[2024-02-22 21:18:04],
   ...
 >}
```

### Try to Create an Invalid User

```sh
iex> Accounts.register_user(%{})

{:error,
 #Ecto.Changeset<
   action: :insert,
   changes: %{},
   errors: [
     password: {"can't be blank",
      [validation: :required]},
     email: {"can't be blank",
      [validation: :required]}
   ],
   data: #Pento.Accounts.User<>,
   valid?: false
 >}
```

## Authenticate The Live View

### Protect Sensitive Routes
- in pento/lib/pento_web/router.ex:
```elixir
  scope "/", PentoWeb do
    pipe_through [:browser, :require_authenticated_user]

    ...
    live "/guess", WrongLive
  end
```

Now, access `http://localhost:4000/guess`.
Click in `sign up` and create an account.

### Access Session Data
- in pento/lib/pento_web/live/wrong_live.ex:
```elixir
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
```

Now, if you refresh the page at /guess , you’ll see a few extra items.