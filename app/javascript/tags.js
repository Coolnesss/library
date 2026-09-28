// Tag chips on the book form (books/_form.html.erb). Enter in the tag input
// adds a chip from the form's template; a chip's ✕ removes it. The server
// normalises the names when the book is saved (Book#tag_names=).
document.addEventListener("keydown", (event) => {
  const input = event.target
  if (input.id !== "new-tag" || event.key !== "Enter") return

  event.preventDefault()
  const name = input.value.trim()
  const taken = [...document.querySelectorAll("#tags input")].some((tag) => tag.value.toLowerCase() === name.toLowerCase())
  if (name && !taken) {
    const chip = document.getElementById("tag-template").content.firstElementChild.cloneNode(true)
    chip.querySelector("[data-tag-name]").textContent = name
    chip.querySelector("input").value = name
    document.getElementById("tags").append(chip)
  }
  input.value = ""
})

document.addEventListener("click", (event) => {
  const remove = event.target.closest("[data-remove-tag]")
  if (remove) remove.closest(".chip").remove()
})
