defmodule MerkleServerTest do
  use ExUnit.Case
    doctest MerkleServer

  setup do
    all_blocks = ["a", "b", "c", "d"]
    mt = MerkleTree.new(all_blocks)

    other_blocks = ["e", "f"]
    other_mt = MerkleTree.new(other_blocks)

    {:ok, server_pid} = MerkleServer.start_link({mt.root.value, []})
    {:ok, server_pid: server_pid, mt: mt, all_blocks: all_blocks, other_mt: other_mt, other_blocks: other_blocks}
  end

  test "should not have blocks after initializing", %{server_pid: pid} do
    assert {:ok, []} == MerkleServer.get_blocks(pid)
  end

  test "should not append block with incorrect proof", %{server_pid: pid, mt: mt} do
    c_block_proof = MerkleTree.Proof.prove(mt, 2) 
    MerkleServer.push(pid, {"b", 1, c_block_proof})
    assert {:ok, []} == MerkleServer.get_blocks(pid)
  end

  test "should append block with correct proof", %{server_pid: pid, mt: mt} do
    b_block_proof = MerkleTree.Proof.prove(mt, 0)
    MerkleServer.push(pid, {"a", 0, b_block_proof})
    assert {:ok, ["a"]} == MerkleServer.get_blocks(pid)
  end

  test "should assemble blocks correctly", %{server_pid: pid, mt: mt, all_blocks: all_blocks} do
    Enum.each([
      {"b", 1, 0}, # wrong
      {"b", 1, 1},
      {"a", 0, 0},
      {"aaaa", 0, 0}, # wrong
      {"d", 3, 3}, 
      {"d", 2, 3}, # wrong
      {"c", 2, 2},
      {"e", 4, 4} # wrong
    ], fn{block, index, proof_index} -> MerkleServer.push(pid, {block, index, MerkleTree.Proof.prove(mt, proof_index)}) end )
    assert {:ok, all_blocks} == MerkleServer.get_blocks(pid)
  end

  test "should drop all received blocks on hash update", %{server_pid: pid, mt: mt, other_mt: other_mt} do
    Enum.each([
      {"b", 1, 1},
      {"a", 0, 0}
    ], fn{block, index, proof_index} -> MerkleServer.push(pid, {block, index, MerkleTree.Proof.prove(mt, proof_index)}) end )
    assert {:ok, ["a", "b"]} == MerkleServer.get_blocks(pid)

    assert {:ok, other_mt.root.value} == MerkleServer.reset(pid, other_mt.root.value)
    assert {:ok, []} == MerkleServer.get_blocks(pid)    
  end

  test "should operate correctly after hash reset", %{server_pid: pid, mt: mt, other_mt: other_mt} do
    # Old transmissions
    Enum.each([
      {"b", 1, 1},
      {"a", 0, 0}
    ], fn{block, index, proof_index} -> MerkleServer.push(pid, {block, index, MerkleTree.Proof.prove(mt, proof_index)}) end )
    assert {:ok, ["a", "b"]} == MerkleServer.get_blocks(pid)
    assert {:ok, other_mt.root.value} == MerkleServer.reset(pid, other_mt.root.value)
    assert {:ok, []} == MerkleServer.get_blocks(pid)        

    # New transmissions
    Enum.each([
      {"b", 1, 1}, # wrong
      {"a", 0, 0}, # wrong
      {"e", 0, 0}, 
      {"f", 1, 1}
    ], fn{block, index, proof_index} -> MerkleServer.push(pid, {block, index, MerkleTree.Proof.prove(other_mt, proof_index)}) end )
    assert {:ok, ["e", "f"]} == MerkleServer.get_blocks(pid)
  end
  
end
