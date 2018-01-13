defmodule MerkleServer do
    # GenServer is a behavior module that will force you to implement certain definitions inside your module
    use GenServer

    @moduledoc """
    Documentation for MerkleServer.
    """

    # Client

    def start_link(default) do
        GenServer.start_link(__MODULE__, default)
    end

    def reset(server_pid, root_hash) do
        GenServer.call(server_pid, {:reset, root_hash})
    end

    def get_blocks(server_pid) do
        GenServer.call(server_pid, {:get_blocks})
    end

    def push(server_pid, {block, index, proof}) do
        GenServer.cast(server_pid, {:push, block, index, proof})
    end


    # Server (callbacks)

    @doc """
    Initialize state with `root_hash` and `blocks`
    """
    def init({root_hash, block_list}) do
        {:ok, {root_hash, indexed_map(block_list)}}
    end
    
    @doc """
    Empty the received items and set a new `root_hash` for the Merkle tree, according to which the proofs should be verified.
    """
    def handle_call({:reset, root_hash}, _from, _state) do
        {:reply, {:ok, root_hash}, {root_hash, %{}}}
    end

    @doc """
    Get all the received blocks.
    """
    def handle_call({:get_blocks}, _from, {root_hash, blocks}) do
        {:reply, {:ok, Map.values(blocks)}, {root_hash, blocks}}
    end

    @doc """
    Default handler
    """
    def handle_call(request, from, state) do
        # Calls are synch
        # {:reply, {actual_response}, state}
        # Or call the default implementation from GenServer  
        super(request, from, state)
    end

    @doc """
    Append a new `block` at `index`, having first asserted the correctness of the `proof`.   
    """
    def handle_cast({:push, block, index, proof}, {root_hash, blocks}) do
        if MerkleTree.Proof.proven?({block, index}, root_hash, proof) do
            {:noreply, {root_hash, Map.put(blocks, index, block)}} 
        else
            {:noreply, {root_hash, blocks}}
        end
    end

    @doc """
    Default handler
    """
    def handle_cast(request, state) do
        # Casts are asynch
        # {:noreply, state}
        # Or call the default implementation from GenServer
        super(request, state)
    end

    # Helper functions

    @doc """
    Creates map from list elements, with keys equal to indexes and values equal to list elements
    """
    def indexed_map(list) do
        list |> Enum.with_index(1) |> Enum.map(fn {k,v}->{v,k} end) |> Map.new
    end
end
