defmodule Memelex.Utils.Encryption do
  @moduledoc """
  Helpers for using Crypto.

  see: https://www.thegreatcodeadventure.com/elixir-encryption-with-erlang-crypto/
  """
  require Logger

  #TODO aes_256_gcm doesnt work for some reason
  @cipher :aes_128_gcm # https://en.wikipedia.org/wiki/Galois/Counter_Mode
                       # http://erlang.org/doc/man/crypto.html#Ciphers
  
  #TODO this should be config/ENV variable - maybe even taken directly from the loaded environment... 
  # @aad "JediLuke-memex" # https://aws.amazon.com/blogs/security/how-to-protect-the-integrity-of-your-encrypted-data-by-using-aws-key-management-service-and-encryptioncontext/
  @aad "AES256GCM"

  @iv_length 32

  # def generate_password do
  #   generate_password(@iv_length)
  # end

  def generate_password(x) do
    :crypto.strong_rand_bytes(x)
    |> :base64.encode
  end

  def generate_secret_key do
    :crypto.strong_rand_bytes(@iv_length)
    # generate_password(@iv_length) # key needs to be 16 for some crypto reason
    # :crypto.strong_rand_bytes(16)
    |> :base64.encode
  end

  def encrypt_file(path, key) do
    if File.dir?(path) do
      :skip
    else
      {:ok, data} = File.read(path)
      encrypted_data = encrypt(data, key)
      Memelex.Utils.FileIO.write(path, encrypted_data)
    end
  end

  def decrypt_file(path, key) do
    if File.dir?(path) do
      :skip
    else
      {:ok, data} = File.read(path)
      decrypted_data = decrypt(data, key)
      Memelex.Utils.FileIO.write(path, decrypted_data)
    end
  end

  def encrypt(plaintext, key) do
    secret_key = :base64.decode(key)
    iv = :crypto.strong_rand_bytes(@iv_length) # initialization_vector

    #NOTE - so, crypto support can vary across systems :( (although, it
    #       still works from Memelex app itself!?)
    # :crypto.supports(:ciphers)

    # IO.inspect(@aad, label: "AAD")

    {ciphertext, ciphertag} =
      :crypto.crypto_one_time_aead(@cipher, secret_key, iv, plaintext, @aad, true)

    iv <> ciphertag <> ciphertext
    |> :base64.encode
  end

  def decrypt(ciphertext, key) do
    secret_key = :base64.decode(key)
    encrypted_msg = :base64.decode(ciphertext)

    # IO.inspect key, label: "KEY"
    #TODO why is this tag always 16 bytes? 16?? But it works! Maybe 32 works aswell... thats 128/256 bit you see
    <<iv::binary-@iv_length, tag::binary-16, ciphertext::binary>> = encrypted_msg

    res = :crypto.crypto_one_time_aead(@cipher, secret_key, iv, ciphertext, @aad, tag, false)

    if res == :error do
      Logger.error "Unable to decrypt ciphertext! Bad key??"
    end

    res
  end
end