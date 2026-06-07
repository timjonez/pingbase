// If you want to use Phoenix channels, import socket.js
// import "./socket"

import "../css/app.css"

// Import dependencies
import {LiveSocket} from "phoenix_live_view"
import {Socket} from "phoenix"

let ScrollBottom = {
  mounted() {
    this.scrollToBottom()
    this.handleEvent("scroll_bottom", () => this.scrollToBottom())
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

let MessageInput = {
  mounted() {
    this.handleEvent("clear_input", () => {
      this.el.value = ""
      this.el.style.height = "auto"
    })

    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault()
        this.el.form.requestSubmit()
      }
    })

    this.el.addEventListener("input", () => {
      this.el.style.height = "auto"
      this.el.style.height = this.el.scrollHeight + "px"
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {ScrollBottom, MessageInput}
})

liveSocket.connect()

window.liveSocket = liveSocket
