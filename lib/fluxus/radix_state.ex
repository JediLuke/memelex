defmodule Memelex.Fluxus.Structs.RadixState do
   alias ScenicWidgets.TextPad.Structs.Font


  def new do
    {:ok, {_type, ibm_plex_mono_font_metrics}} = Scenic.Assets.Static.meta(:ibm_plex_mono)

    # NOTE - when just running Memelex, we don't really use the `root`
    # or `gui` sections of the RadixState
    %{
      root: %{
        active_app: :memex
      },
      gui: %{
        viewport: nil,
      },
      memex: %{
        story_river: %{
          open_tidbits: [],
          scroll: {0, 0}
        }
      }
    }
  end

end
