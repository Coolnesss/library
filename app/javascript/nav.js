// The menu button opens the off-canvas sidebar on narrow screens; the overlay
// behind it closes it. The ✕ on a flash message dismisses it. A click outside
// the language menu closes it.
document.addEventListener("click", (event) => {
  for (const menu of document.querySelectorAll("details.language-menu[open]")) {
    if (!menu.contains(event.target)) menu.open = false
  }

  const sidebar = document.getElementById("sidebar-id")

  if (event.target.closest("#nav-toggle")) {
    sidebar?.classList.add("active")
  } else if (event.target.closest("#nav-toggle-remove")) {
    sidebar?.classList.remove("active")
  } else if (event.target.closest(".toast .btn-clear")) {
    event.target.closest(".toast").remove()
  }
})
