defmodule PingbaseWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a flash message.
  """
  attr :id, :string, default: nil, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, doc: "the optional title of flash message"
  attr :kind, :atom, values: [:info, :error], doc: "used for icons and colors"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={if @id, do: JS.push("lv:clear-flash") |> JS.hide(to: "##{@id}"), else: JS.push("lv:clear-flash")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <%= msg %>
      </p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label="close">
        <svg class="h-5 w-5 opacity-40 group-hover:opacity-70" viewBox="0 0 20 20" fill="currentColor">
          <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
        </svg>
      </button>
    </div>
    """
  end

  @doc """
  Renders flash group.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} id="flash-info" flash={@flash} />
    <.flash kind={:error} id="flash-error" flash={@flash} />
    """
  end
end
