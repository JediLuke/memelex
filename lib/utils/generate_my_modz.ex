defmodule Memelex.Utils.GenerateMyModz do
@moduledoc """
This module programatically generates a `my_modz.ex` file
in a new Memex environment.
"""


    def new(%{name: memex_name}) when is_bitstring(memex_name) do
        ~s|defmodule Memelex.My do
            require Logger

            def nickname, do: #{memex_name}

            #{def_my_modz()}

            #{def_custom_input_handler()}

            #{def_my_datetime()}

            @doc ~s{This is here just to provide a nice API, My.todos()}
            def todos do
                Memelex.My.TODOs.list()
            end

        end|
    end

    def def_my_modz do
        ~s|defmodule Modz do
            
            #{def_on_boot()}

        end|
    end

    def new_custom(%{name: memex_name}) do
        
        #TODO this will work for JediLuke but we should do some more stringent checks that this is a valid module name before we actually let this through...

        ~s|defmodule #{memex_name} do
            
            def hello do
                "Hi :)"
            end

        end|
    end

    def def_on_boot do
        #NOTE - because we want to write some interpolated IEx to the file,
        # we want to use capital S string sigil here, just create a raw string
        ~S|def on_boot(%{name: env_name}) when is_bitstring(env_name) do
            Logger.info "Loading modz for `#{env_name}`..."
            :ok
        end|
    end

    def def_custom_input_handler do
        ~s|defmodule CustomInputHandler do
            use ScenicWidgets.ScenicEventsDefinitions
        
            #def process(radix_state, @lowercase_s) do
            #    Flamelex.API.Buffer.save()
            #    :ignore
            #end
        
            def process(_radix_state, input) do
                :ignore
            end
        end|
    end

    def def_my_datetime do

        #TODO get timezone from Memex or somewhere else, maybe set to nil?

        ~s{def current_time do
            timezone() |> DateTime.now!()
        end
        
  
        def timezone do
            "America/Chicago"
        end}
    end

end






# this is an example of a whole template module we could inject into
# the my_modz whenever necessary

# defmodule Memelex.My.Docs do
#     alias Memelex.WikiServer
  
#     @tag "my_docs"
  
#     def new(%{tags: tlist} = params) when is_list(tlist) do
#       Memelex.Utils.Validation.validate_tag_list!(tlist)
#       params
#       |> Map.merge(%{tags: tlist ++ [@tag]})
#       |> Memelex.My.Wiki.new()
#     end
  
#     def new(params) when is_map(params) do
#       params
#       |> Map.merge(%{tags: [@tag]})
#       |> Memelex.My.Wiki.new()
#     end
  
#     @doc ~s(Fetch the whole list of TODOs)
#     def list do
#       {:ok, tidbits} =
#         WikiManager |> GenServer.call(:list_all_tidbits)
  
#       tidbits
#       |> Enum.filter(fn(tidbit) -> tidbit.tags |> Enum.member?(@tag) end)
#     end
  
#   end