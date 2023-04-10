defmodule Memelex.Fluxus.Structs.RadixState do
  #  alias ScenicWidgets.TextPad.Structs.Font


  def init do
    # {:ok, {_type, ibm_plex_mono_font_metrics}} = Scenic.Assets.Static.meta(:ibm_plex_mono)

    %{
      name: Application.get_env(:memelex, :environment).name,
      active?: Application.get_env(:memelex, :active?), # If the Memex is disabled at the app config level, we need to ignore a lot of actions
      gui: %{
        viewport: nil,
      },
      story_river: %{
        focussed_tidbit: nil,
        open_tidbits: [],
        #TODO put the scroll in another process, then it a) will hopefully be more seperated and b) we can just update that one (maybe even just by calling update_opts) and don't have to re-render every component we're scrolling, which is kinda crazy
        scroll: {0, 0}
      },
      sidebar: %{
        # active_tab: :ctrl_panel,
        # search: %{
        #   active?: false,
        #   string: ""
        # }
      },
      history: %{
        keystrokes:   [],
        # actions:      []
     }
    }
  end

end
