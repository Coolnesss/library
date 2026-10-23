// Tag chips (books/_tag_chip.html.erb), on the book form and in the search
// filters. In a [data-tag-input], Enter or a comma adds the typed tag to its
// [data-tags] group, and choosing one of the suggestions adds it at once. A
// chip's ✕ removes it. The server normalises the names when the book is saved
// (Book#tag_names=).
document.addEventListener("keydown", (event) => {
  const input = event.target
  if (!input.matches("[data-tag-input]") || (event.key !== "Enter" && event.key !== ",")) return

  event.preventDefault()
  addTypedTag(input)
})

// A suggestion chosen from the list arrives as an input event that replaces
// the text (Safari sends no inputType), never as typing.
document.addEventListener("input", (event) => {
  const input = event.target
  if (!input.matches("[data-tag-input]")) return
  if (event.inputType && event.inputType !== "insertReplacementText") return

  const name = input.value.trim().toLowerCase()
  if ([...(input.list?.options || [])].some((option) => option.value.toLowerCase() === name)) addTypedTag(input)
})

// A tag typed but not yet added still counts when the book form is saved. (The
// search's input carries the tags[] name itself, so it counts already.) In the
// capture phase, so it runs before Turbo reads the form.
document.addEventListener("submit", (event) => {
  event.target.querySelectorAll("[data-tag-input]:not([name])").forEach((input) => addTypedTag(input))
}, true)

document.addEventListener("click", (event) => {
  const remove = event.target.closest("[data-remove-tag]")
  if (remove) remove.closest(".chip").remove()
})

function addTypedTag(input) {
  const group = input.closest("[data-tags]")
  const chips = group.querySelector("[data-tag-chips]")
  const name = input.value.replace(/,/g, " ").trim()
  const taken = [...chips.querySelectorAll("input")].some((tag) => tag.value.toLowerCase() === name.toLowerCase())
  if (name && !taken) {
    const chip = group.querySelector("template").content.firstElementChild.cloneNode(true)
    chip.querySelector("[data-tag-name]").textContent = name
    chip.querySelector("input").value = name
    chips.append(chip)
  }
  input.value = ""
}
