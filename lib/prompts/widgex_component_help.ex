# defmodule Memelex.Lib.Prompts.WidgexComponentHelp do
#   @moduledoc """
#   A utility module to generate prompts for Elixir/Scenic projects by dynamically reading files.
#   """

#   @prompt_template """
#   I need help on my Elixir/Scenic project. I have developed an internal architecture of the project which is supposed to be based on the `flux` architecture that React is based off - immutable actions get passed through pure-function reducers to return changes to a state. This state change gets broadcast out and components react to those changes.

#   I have learned a lot about working with Scenic and I have developed some patterns which help me to develop components. To assist you, I will step you through my application as much as possible to explain how everything works, and why I have established the patterns that I have.

#   When the app boots, I start a Scenic Scene. This Scene boots some sub-components which I call 'layers', logically they act as layers but really they're just Scenic components. This is some code from that root scene showing where I add the layers:

#   ```
#   full_graph =
#       Scenic.Graph.build()
#       |> Layer0.add_to_graph(%{frame: app_frame})
#       |> Layer01.add_to_graph(%{frame: app_frame})
#       |> NeoLayer02.add_to_graph(%{
#       id: :menubar,
#       frame: full_window,
#       state: NeoLayer02.cast_rdx_to_layer_state(radix_state)
#       })
#       # popups & modals
#       |> Layer3.add_to_graph(%{frame: app_frame})
#       # Kommander
#       |> Layer4.add_to_graph(%{frame: app_frame})
#   ```

#   Let's look at one of the layers. Here, this is layer 1 component:

#   ```
#   cat "$LAYER_1_FILE"
#   ```

#   You can see the layer component fetches it's initia state from RadixDStpre (which we will come to in a moment)
#   and calls render (which is in a seperate module for convenienve and organization purposes).

#   RadixStore is a genserver which holds pretty much the entire state of the application. When we want to make
#   changes to RadixStore, we fire an "action" - this is how we would fire an action using the "API" (convenienve modules
#   to provide a nice interface to the programmer/user)

#   ```
#   def switch(n) when is_integer(n) do
#     Flamelex.Fluxus.action({Flamelex.GUI.Component.QlxWrap, {:activate_buffer, n}})
#   end
#   ```

#   These actions get routed as events to the RadixStore, which processes them sequentially. Here "processing" means
#   combining the action with the current state, to find the appropriate reducer function to run, which will return an
#   updated state. Here are some examples:

#   Here radix handles events:

#   ```
#   def handle_call({:event, e}, _from, radix_state) do
#     # this can make a lot of noise, but sometimes I need to see it
#     crush_report? = true

#     case Wormhole.capture(handle_event_fn(radix_state, e), crush_report: crush_report?) do
#       {:ok, :ignore} ->
#         # EventBus.mark_as_completed({__MODULE__, e_shadow})
#         {:reply, {:ok, :ignore}, radix_state}

#       {:ok, new_radix_state} ->
#         # so for now, we're just going to double-down on this being the single channel
#         # I have a big debate about this because I feel like this is going to be very expensive,
#         # broadcasting out multiple copies of the RadixState! However, this is
#         # the simplest way to do it, and we can always optimize later. I am not able to
#         # really wrap my head around how I would do it otherwise... maybe I simply push the radix state
#         # through a reducer which has side-effects of broadcasting out messages on specific channels?
#         # that might make it possible to broadcast smaller state changes

#         # yeh I guess we could iterate just changes out instead of pushing entire changes to radixstate,
#         # then other things e.g. GUI components all need to be able to handle specific changes... it gets complicated

#         # one idea would be to broadcast the action first to radix state, then radix state
#         # has control and can broadcast (potentially modified) actions down to it's
#         # children (or just publish it on a channel), the child stores can then
#         # update their state and broadcast out their changes

#         # The problem becomes when we need to access different parts of the state tree, or if
#         # something deeply nested within the state tree ends up affecting decisions made early/high in the funnel,
#         # which maybe shouldn't happen but somehow it seems to all the time...

#         # there's another idea which is, broadcast actions out to _all_ the stores, they decide individually if
#         # they care about it, and if they do, then they might broadcast just their own state changes out on their own channel
#         # to whatever GUI components are listening to those changes

#         Flamelex.Lib.Utils.PubSub.broadcast(
#           topic: :radix_state_change,
#           msg: {:radix_state_change, new_radix_state}
#         )

#         # EventBus.mark_as_completed({__MODULE__, e_shadow})
#         {:reply, {:ok, new_radix_state}, new_radix_state}

#       {:error, _reason} ->
#         formatted_error = ~s|\n
#         id: #{e.id},
#         topic: #{e.topic},
#         event: #{inspect(e.data)}
#         |

#         Logger.error("#{__MODULE__} failed to process event.#{formatted_error}")

#         # EventBus.mark_as_completed({__MODULE__, e_shadow})
#         {:reply, {:error, "#{__MODULE__} failed to process event."}, radix_state}
#     end
#   end
#     ```

#     the upshot is that it will call radix reducer

#     ```
#     defp handle_event_fn(radix_state, %{topic: :flx_actions, data: action}) do
#     # have to return a zero arity function for Task.async
#     fn ->
#       case Flamelex.Fluxus.RadixReducer.process(radix_state, action) do
#         :ignore ->
#           # EventBus.mark_as_completed({__MODULE__, e_shadow})
#           :ignore

#         ^radix_state ->
#           # EventBus.mark_as_completed({__MODULE__, e_shadow})
#           :ignore

#         # cast to children ?? This might also involve a push down of new RadixState ??

#         %Flamelex.Fluxus.RadixState{} = new_radix_state ->
#           # EventBus.mark_as_completed({__MODULE__, e_shadow})
#           new_radix_state
#       end
#     end
#   end
#     ```

#     radix reducers job is to bring together the current state, the action we want to apply, and figure out how
#     to do it. TO break this task down I have written/organized reducers into modules which are sort of attached
#     to the scenic components themselves. This was nothing but a routing strategy and at the end of the day, may
#     not be the way to go. But it's what I did

#     ```



#   - Primary challenges for me have been, writing scenic render components in a way such that they can handle the cases
#   of both adding new components to a graph that doesn have them, or updating components in place based on changes in state.
#   - keeping track of all the changes that now need to be done to make a change - it's structured, but it's not without overhead


#   @doc """
#   Generates a prompt by reading the specified file.

#   ## Parameters
#   - file_path: The path to the file to include in the prompt.

#   ## Examples

#       iex> PromptGenerator.generate("./lib/gui/layers/layer_1/laye_1.ex")
#       "I need help on my Elixir/Scenic project..."

#   """
#   def generate(file_path) do
#     case File.read(file_path) do
#       {:ok, file_content} ->
#         """
#         #{@prompt_template}

#         File content:

#         ```elixir
#         #{file_content}
#         ```
#         """

#       {:error, reason} ->
#         "Error reading file: #{reason}"
#     end
#   end


# end
