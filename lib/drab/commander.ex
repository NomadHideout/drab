defmodule Drab.Commander do
  require Logger

  @moduledoc """
  Drab Commander is a module to keep event handlers.

  All the Drab functions (callbacks, event handlers) are placed in the module called `Commander`. Think about 
  it as a controller for the live pages. Commanders should be placed in `web/commanders` directory. Commander must
  have a corresponding controller.

      defmodule DrabExample.PageCommander do
        use Drab.Commander

        def click_button_handler(socket, dom_sender) do
          ...
        end
      end

  Remember the difference: `controller` renders the page while `commander` works on the live page.

  ## Event handler functions

  The event handler function receives two parameters:
  * `socket` - a websocket used to communicate back to the page by `Drab.Query` functions
  * `dom_sender` - a map contains information of the object which sent the event; `dom_sender` map keys are binary strings

  The `dom_sender` map:

      %{
        "id"    => "sender object ID attribute",
        "name"  => "sender object 'name' attribute",
        "class" => "sender object 'class' attribute",
        "text"  => "sender node 'text'",
        "html"  => "sender node 'html', result of running .html() on the node",
        "val"   => "sender object value",
        "data"  => "a map with sender object 'data-xxxx' attributes, where 'xxxx' are the keys",
        "drab_id" => "internal"
      }

  ## Callbacks 

  Callbacks must be specified in `use Drab.Commander` clause:

      defmodule DrabExample.PageCommander do
        use Drab.Commander, onload: :page_loaded, onconnect: :connected

        def page_loaded(socket) do
          ...
        end

        def connected(socket) do
          ...
        end
      end

  Callbacks:
  * `onload` - launched only once after page loaded and connects to the server - exactly the same like `onconnect`, 
    but launches only once, not after every reconnect
  * `onconnect` - launched every time client browser connects to the server, including reconnects after server 
    crash, network broken etc
  * `ondisconnect` - launched every time client browser disconnects from the server, it may be a network disconnect,
    closing the browser, navigate back

  ## Modules

  Drab is modular. You my choose which modules to use in the specific Commander by using `:module` option
  in `use Drab.Commander` directive. 
  There is one required module, which is loaded always and can't be disabled: `Drab.Code`. By default, modules
  `Drab.Query` and `Drab.Modal` are loaded. The following code:

      use Drab.Commander, modules: [Drab.Query]

  will enable only `Drab.Core` and `Drab.Query`.

  Every module has its corresponding JS template, which is loaded only when module is enabled.

  ## Store
  Drab may allow an access to specified Plug Session values. For this, you must whitelist the keys of the 
  session map. Only this keys will be available to `Drab.Core.get_store/2`

      use Drab.Commander, inherit_session: [:user_id]

  ## Generate the Commander

  There is a mix task (`Mix.Tasks.Drab.Gen.Commander`) to generate skeleton of commander:

      mix drab.gen.commander Name

  See also `Drab.Controller`
  """

  defmacro __using__(options) do
    quote do      
      import Drab.Core

      unquote do
        opts = Map.merge(%Drab.Config{}, Enum.into(options, %{}))
        opts.modules |> Enum.map(fn module -> 
          quote do
            import unquote(module)
          end
        end)
      end

      # Module.put_attribute(__MODULE__, :__drab_opts__, unquote(options))
      unless Module.defines?(__MODULE__, {:__drab__, 0}) do
        def __drab__() do
          opts = Enum.into(unquote(options), %{commander: __MODULE__})
          Map.merge(%Drab.Config{}, opts) 
        end
      end

      # This function is launched from Drab.init
      # It starts the process which reacts on server die; launching `ondisconnect` callback in this case
      # def __drab_closing_waiter__(socket) do
      #   if __drab__().ondisconnect do
      #     # Logger.debug("Closing waiter: #{socket|>inspect}")
      #     spawn_link fn ->
      #       Process.flag(:trap_exit, true)
      #       receive do
      #         {:EXIT, _pid, {:shutdown, :closed}} -> 
      #           Logger.debug(inspect(socket.assigns.drab_pid))
      #           Logger.debug(inspect(Process.alive?(socket.assigns.drab_pid)))
      #           # socket_for_this_moment = Drab.get_socket(socket.assigns.drab_pid)
      #           # Logger.debug("Socket get from Drab in closing waiter: #{socket_for_this_moment |> inspect}")
      #           # Launch ondisconnect event
      #           apply(__drab__().commander, __drab__().ondisconnect, [socket])
      #           exit(:normal)
      #         other ->
      #           Logger.warn """
      #             Drab Closing Waiter received unknown message: #{inspect(other)}.
      #             Ondisconnect handler will not be launched.
      #             """
      #       end
      #     end
      #   else
      #     socket
      #   end
      # end

    end
  end

end
