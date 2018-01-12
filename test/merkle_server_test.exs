defmodule MerkleServerTest do
  use ExUnit.Case
  doctest MerkleServer

  setup do
    {:ok, server_pid} = MerkleServer.start_link(['a', 'b', 'c', 'd'])
    {:ok, server: server_pid}
  end

  test "get blocks", %{server: pid} do
    assert {:ok, ['a', 'b', 'c', 'd']} == MerkleServer.get_blocks(pid)
  end
  
end
