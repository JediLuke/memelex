defmodule Memex.Utils.Encryption do
  @moduledoc """
  Helpers for using Crypto.

  see: https://www.thegreatcodeadventure.com/elixir-encryption-with-erlang-crypto/
  """

  #TODO aes_256_gcm doesnt work for some reason
  @cipher :aes_128_gcm # https://en.wikipedia.org/wiki/Galois/Counter_Mode
                       # http://erlang.org/doc/man/crypto.html#Ciphers
  
  #TODO this should be config/ENV variable - maybe even taken directly from the loaded environment... 
  @aad "JediLuke-memex" # https://aws.amazon.com/blogs/security/how-to-protect-the-integrity-of-your-encrypted-data-by-using-aws-key-management-service-and-encryptioncontext/

  @iv_length 32

  def generate_secret_key do
    :crypto.strong_rand_bytes(16)
    |> :base64.encode
  end

  def encrypt(plaintext, key) do
    secret_key = :base64.decode(key)
    iv = :crypto.strong_rand_bytes(@iv_length) # initialization_vector

    {ciphertext, ciphertag} =
      :crypto.crypto_one_time_aead(@cipher, secret_key, iv, plaintext, @aad, true)

    iv <> ciphertag <> ciphertext
    |> :base64.encode
  end

  def decrypt(ciphertext, key) do
    secret_key = :base64.decode(key)
    encrypted_msg = :base64.decode(ciphertext)

    #TODO why is this tag always 16 bytes? 16?? But it works!
    <<iv::binary-@iv_length, tag::binary-16, ciphertext::binary>> = encrypted_msg

    :crypto.crypto_one_time_aead(@cipher, secret_key, iv, ciphertext, @aad, tag, false)
  end
end