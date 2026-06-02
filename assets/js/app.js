// If you want to use Phoenix channels, import socket.js
// import "./socket"

import "../css/app.css"

// Import dependencies
import {LiveSocket} from "phoenix_live_view"
import {Socket} from "phoenix"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {}
})

liveSocket.connect()

window.liveSocket = liveSocket
