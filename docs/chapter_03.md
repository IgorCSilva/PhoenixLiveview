# Generators: Contexts and Schemas

## Run the phx.live Generator

### Learn How To Use the Generator

Run `mix phx.gen.live`.
You will see some help informations.

### Generate a Resource
Run
`mix phx.gen.live Catalog Product products name:string description:string unit_price:float sku:integer:unique`

- in pento/lib/pento_web/router.ex:
```elixir
  scope "/", PentoWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", PageController, :home
    live "/guess", WrongLive
    
    live "/products", ProductLive.Index, :index
    live "/products/new", ProductLive.Index, :new
    live "/products/:id/edit", ProductLive.Index, :edit

    live "/products/:id", ProductLive.Show, :show
    live "/products/:id/show/edit", ProductLive.Show, :edit
  end
```

## Understand The Generated Core