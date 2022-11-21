defmodule Memelex.Assets do
  use Scenic.Assets.Static,
    otp_app: :memelex,
    alias: [
      ibm_plex_mono: "fonts/IBMPlexMono-Regular.ttf"
    ]
end
