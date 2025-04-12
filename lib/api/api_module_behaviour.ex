defmodule Memelex.Behaviours.ApiModule do
  # @callback my_function1(arg1 :: any, arg2 :: any) :: any
  # @callback my_function2(arg1 :: any, arg2 :: any) :: any

  defmacro __using__(macro_opts) do
    quote location: :keep, bind_quoted: [macro_opts: macro_opts] do
      @behaviour ApiModuleBehaviour

      def tag do
        if is_nil(@tag), do: raise("You must set a tag for this API module.")
        @tag
      end

      def new(title) when is_binary(title) do
        new(%{title: title})
      end

      def new(params) when is_map(params) do
        if is_nil(@tag), do: raise("You must set a tag for this API module.")

        params
        |> Map.merge(%{tags: Map.get(params, :tags, []) ++ [@tag]})
        |> Memelex.My.Wiki.new()
      end

      def all do
        # TODO don't use list_all & filter... do it inside WIkiServer
        {:ok, tidbits} = GenServer.call(Memelex.WikiServer, :list_all_tidbits)
        Enum.filter(tidbits, &Enum.member?(&1.tags, @tag))
      end

      # defmacro __before_compile__(_) do
      #   quote do
      #     defmacro __using__(_) do
      #       quote do
      #         @behaviour ApiModuleBehaviour
      #       end
      #     end
      #   end
      # end
    end
  end
end
