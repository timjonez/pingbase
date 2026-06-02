defmodule PingbaseWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.
  """
  use PingbaseWeb, :html

  def render("404.html", _assigns) do
    "Not Found"
  end

  def render("500.html", _assigns) do
    "Internal Server Error"
  end

  def render(_template, _assigns) do
    "Internal Server Error"
  end
end
