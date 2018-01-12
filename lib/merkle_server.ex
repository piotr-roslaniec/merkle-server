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
        GenServer.cast(server_pid, {:push, {block, index, proof}})
    end


    # Server (callbacks)

    @doc """
    Initialize state with MerkleTree given `blocks`
    """
    def init(blocks) do
        {:ok, MerkleTree.new(blocks)}
    end
    
    @doc """
    Empty the received items and set a new `root_hash` for the Merkle tree, according to which the proofs should be verified.
    """
    def handle_call({:reset, root_hash}, _from, state) do
        {:reply, {root_hash}, state}
    end

    @doc """
    Get all the received blocks.
    """
    def handle_call({:get_blocks}, _from, state) do
        {:reply, {:ok, state.blocks()}, state}
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
    def handle_cast({:push, block, index, proof}, state) do
        {:noreply, {:push, block, index, proof}, state}
    end

    @doc """
    Default handler
    """
    def handle_cast(request, state) do
        # Casts are asynch
        # {:noreply, {actual_response}, state}
        # Or call the default implementation from GenServer
        super(request, state)
    end
    
end
