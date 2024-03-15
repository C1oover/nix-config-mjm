defmodule HomelabWeb.Layouts do
  use HomelabWeb, :html

  embed_templates("layouts/*")

  def navbar(assigns) do
    ~H"""
    <nav x-data="{ mobileOpen: false }" class="bg-gray-800 dark:bg-gray-900">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <.link navigate={~p"/"}>
                <.icon name="hero-home" class="h-6 w-6 text-gray-100" />
              </.link>
            </div>

            <div class="hidden md:block">
              <div class="ml-10 flex items-baseline space-x-4">
                <.nav_link view_item={@nav_item} item={:backups} navigate={~p"/backups"}>
                  <.icon name="hero-circle-stack-solid" class="h-4 w-4 mr-2" /> Backups
                </.nav_link>

                <.nav_link view_item={@nav_item} item={:deploys} navigate={~p"/deploys"}>
                  <.icon name="hero-code-bracket-solid" class="h-4 w-4 mr-2" /> Deploys
                </.nav_link>

                <.nav_link view_item={@nav_item} item={:tasks} navigate={~p"/tasks"}>
                  <.icon name="hero-document-check" class="h-4 w-4 mr-2" /> Tasks
                </.nav_link>
              </div>
            </div>
          </div>

          <div class="-mr-2 flex md:hidden">
            <button
              @click="mobileOpen = !mobileOpen"
              class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:bg-gray-700 focus:text-white"
              aria-controls="mobile-menu"
              x-bind:aria-expanded="mobileOpen"
            >
              <span class="sr-only">Open main menu</span>
              <.icon name="hero-x-mark" class="h-6 w-6 block" x-cloak x-show="mobileOpen" />
              <.icon name="hero-bars-3" class="h-6 w-6 block" x-show="!mobileOpen" />
            </button>
          </div>
        </div>
      </div>

      <div x-cloak x-show="mobileOpen" class="md:hidden" id="mobile-menu">
        <div class="px-2 pt-2 pb-3 space-y-1 sm:px-3">
          <.mobile_nav_link view_item={@nav_item} item={:backups} navigate={~p"/backups"}>
            Backups
          </.mobile_nav_link>

          <.mobile_nav_link view_item={@nav_item} item={:deploys} navigate={~p"/deploys"}>
            Deploys
          </.mobile_nav_link>

          <.mobile_nav_link view_item={@nav_item} item={:tasks} navigate={~p"/tasks"}>
            Tasks
          </.mobile_nav_link>
        </div>
      </div>
    </nav>
    """
  end

  attr(:item, :atom, required: true)
  attr(:view_item, :atom, required: true)
  attr(:rest, :global, include: ~w(navigate patch))
  slot(:inner_block, required: true)

  def nav_link(assigns) do
    ~H"""
    <.link
      class={"inline-flex items-center px-3 py-2 rounded-md text-sm font-medium #{if not is_nil(@item) and @view_item == @item, do: "text-white bg-gray-900 dark:bg-gray-800", else: "text-gray-300 hover:text-white hover:bg-gray-700"} focus:outline-none focus:text-white focus:bg-gray-700"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  attr(:item, :atom, required: true)
  attr(:view_item, :atom, required: true)
  attr(:rest, :global, include: ~w(navigate patch))
  slot(:inner_block, required: true)

  def mobile_nav_link(assigns) do
    ~H"""
    <.link
      class={"flex flex-col px-3 py-2 rounded-md text-base font-medium #{if not is_nil(@item) and @view_item == @item, do: "text-white bg-gray-900", else: "text-gray-300 hover:text-white hover:bg-gray-700"} focus:outline-none focus:text-white focus:bg-gray-700"}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
