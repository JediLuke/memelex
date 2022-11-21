defmodule Memelex.Fluxus.Structs.RadixState do
   alias ScenicWidgets.TextPad.Structs.Font


  def new do
    {:ok, {_type, ibm_plex_mono_font_metrics}} = Scenic.Assets.Static.meta(:ibm_plex_mono)

    %{
      root: %{
        active_app: :memex,
        graph: nil
      },
      gui: %{
        viewport: nil,
      },
      memex: %{

      }
    }
  end

end
