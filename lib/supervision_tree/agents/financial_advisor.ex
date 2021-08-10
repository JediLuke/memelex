defmodule Memex.Agents.FinancialAdvisor do
  use GenServer
  require Logger
  alias Memex.Utils
 

  # starts up, in turn, a process which does accounting?
  # tax?
  # insurance planning?
  # budgeting?
  # investments?

  # for starters, needs to keep track of my bills... (& then pay them!) - and also needs to track receipts!

  # Should be helping to boost my credit rating!
  # Should be trying to help boost my wealth
  # Should be making sure I'm addequately insured / hedged

  # need to track my expenditure

 
  def start_link(params)  do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end


  @impl GenServer
  def init(_params) do
    Logger.info "#{__MODULE__} initializing..."
    {:ok, %{}, {:continue, :boot_sequence}}
  end

  @impl GenServer
  def handle_continue(:boot_sequence, state) do
    Process.send_after(self(), :main_loop, :timer.minutes(10))
    {:noreply, state}
  end

  def handle_cast(:main_loop, state) do
    GenServer.cast(self(), :process_accounts_payable)
    {:noreply, state}
  end

  def handle_cast(:process_accounts_payable, state) do
    # find my list of bills in the Memex
    bills = Memex.My.Wiki.find(%{tags: ["my_bills"]})
    IO.inspect bills, label: "FINANCE GUY FOUND THESE BILLS"
    {:noreply, state}
  end

end