// Leaves the book search's empty fields out of the URL, so a search for one
// word reads /books?q=word rather than listing every blank filter.
document.addEventListener("formdata", (event) => {
  if (!event.target.matches("[data-book-search]")) return

  // delete() drops every entry of a key, so rebuild the list: tags[] can hold
  // an empty value next to real ones.
  const entries = [...event.formData.entries()]
  for (const [key] of entries) event.formData.delete(key)
  for (const [key, value] of entries) {
    if (value !== "") event.formData.append(key, value)
  }
})
