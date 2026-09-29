// Tag chips (books/_tag_chip.html.erb), on the book form and in the search
// filters. Enter in a [data-tag-input] adds a chip to its [data-tags] group,
// cloned from the group's template; a chip's ✕ removes it. The server
// normalises the names when the book is saved (Book#tag_names=).
document.addEventListener("keydown", (event) => {
  const input = event.target
  if (!input.matches("[data-tag-input]") || event.key !== "Enter") return

  event.preventDefault()
  const group = input.closest("[data-tags]")
  const chips = group.querySelector("[data-tag-chips]")
  const name = input.value.trim()
  const taken = [...chips.querySelectorAll("input")].some((tag) => tag.value.toLowerCase() === name.toLowerCase())
  if (name && !taken) {
    const chip = group.querySelector("template").content.firstElementChild.cloneNode(true)
    chip.querySelector("[data-tag-name]").textContent = name
    chip.querySelector("input").value = name
    chips.append(chip)
  }
  input.value = ""
})

document.addEventListener("click", (event) => {
  const remove = event.target.closest("[data-remove-tag]")
  if (remove) remove.closest(".chip").remove()
})
