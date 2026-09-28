// The menu button opens the off-canvas sidebar on narrow screens; the overlay
// behind it closes it. The ✕ on a flash message dismisses it.
document.addEventListener("click", (event) => {
  const sidebar = document.getElementById("sidebar-id")

  if (event.target.closest("#nav-toggle")) {
    sidebar?.classList.add("active")
  } else if (event.target.closest("#nav-toggle-remove")) {
    sidebar?.classList.remove("active")
  } else if (event.target.closest(".toast .btn-clear")) {
    event.target.closest(".toast").remove()
  }
})
