// The book form's upload (books/_form.html.erb). Picking a file uploads it
// straight away, with a progress bar (Active Storage direct upload). For a
// PDF, pdf.js then reads its title, author and page count into the fields
// left empty and renders page 1 as the cover, uploaded the same way. The year
// comes from the file name, where nearly every book has one. The form then
// sends signed ids instead of the file.
//
// Without JavaScript, or if any step fails, the file input still sends the
// file with the form and the server renders the cover (CreateCoversJob).
import { DirectUpload } from "@rails/activestorage"

const ARABIC = /\p{Script=Arabic}/u
// Letters only one of the two languages uses, to tell Sindhi from Urdu.
const SINDHI_LETTERS = /[ٻڀٽٿٺڄڃڇڊڌڏڍڙڻڦڱڳڪ]/
const URDU_LETTERS = /[ےںٹڈڑ]/
const YEAR = "(1[89]\\d\\d|20\\d\\d)"
const COVER_SIZE = 1024 // long side in pixels, like CreateCoversJob
let picks = 0

document.addEventListener("change", (event) => {
  const input = event.target
  if (!input.matches("[data-book-file]")) return

  const form = input.form
  const file = input.files[0]
  const pick = String(++picks)
  form.dataset.pick = pick
  const current = () => form.isConnected && form.dataset.pick === pick
  const name = form.querySelector("[data-file-name]")
  name.textContent = file ? file.name : name.dataset.none
  startOver(form, input)
  if (!file) return

  uploadFile(form, input, file, current)
  fill(form, "year", fileNameYear(file.name))

  const read = file.type === "application/pdf" ? readPdf(form, file, current) : Promise.resolve()
  read.catch((error) => console.warn("Could not read the PDF in the browser:", error))
      .then(() => { if (current()) fillFromFileName(form, file.name) })
})

// Nothing is sent while an upload is still running. In the capture phase, so
// Turbo, which skips a submit already prevented, never sees it.
document.addEventListener("submit", (event) => {
  if (Number(event.target.dataset.pending) > 0) event.preventDefault()
}, true)

// A new pick replaces whatever the last one, or a failed save, left behind.
function startOver(form, input) {
  input.name = input.dataset.name
  form.querySelectorAll("[data-js-field], [data-kept]").forEach((element) => element.remove())
  form.querySelectorAll(".autofilled").forEach((element) => element.classList.remove("autofilled"))
  form.querySelector("[data-autofill-note]").hidden = true
  form.querySelector("[data-book-pages]").value = ""
  const preview = form.querySelector("[data-cover-preview]")
  preview.hidden = true
  preview.removeAttribute("src")
  showProgress(form, null)
}

function uploadFile(form, input, file, current) {
  showProgress(form, 0)
  track(form, directUpload(input.dataset.directUploadUrl, file, (fraction) => { if (current()) showProgress(form, fraction) }))
    .then((signedId) => {
      if (!current()) return
      setField(form, "book[attachment]", signedId)
      // Sent as a signed id now, so the file itself stays out of the form.
      input.removeAttribute("name")
      showProgress(form, "done")
    })
    .catch((error) => {
      console.warn("Direct upload failed; the form will send the file:", error)
      if (current()) showProgress(form, "failed")
    })
}

async function readPdf(form, file, current) {
  const pdfjs = await import("pdfjs")
  pdfjs.GlobalWorkerOptions.workerSrc = form.dataset.pdfWorker

  const pdf = await pdfjs.getDocument({ ...await source(pdfjs, file), isEvalSupported: false }).promise
  try {
    if (!current()) return
    form.querySelector("[data-book-pages]").value = pdf.numPages

    const { info, metadata } = await pdf.getMetadata()
    if (!current()) return
    const title = clean(info?.Title) || clean(metadata?.get("dc:title"))
    fillByScript(form, title, "name", "name_eng")
    fillByScript(form, clean(info?.Author) || clean(metadata?.get("dc:creator")), "author_sindhi", "author")
    fill(form, "language", guessLanguage(title))

    const cover = await renderCover(pdf)
    if (!current()) return
    const preview = form.querySelector("[data-cover-preview]")
    preview.src = URL.createObjectURL(cover)
    preview.hidden = false
    const input = form.querySelector("[data-book-file]")
    const signedId = await track(form, directUpload(input.dataset.directUploadUrl, new File([cover], "cover.jpg", { type: "image/jpeg" })))
    if (current()) setField(form, "book[cover]", signedId)
  } finally {
    pdf.destroy()
  }
}

// Small files are read whole. Big ones are read in the pieces pdf.js asks
// for, so a scan of a few hundred MB never has to fit in a phone's memory.
async function source(pdfjs, file) {
  if (file.size <= 4 * 1024 * 1024) return { data: new Uint8Array(await file.arrayBuffer()) }

  const range = new pdfjs.PDFDataRangeTransport(file.size, new Uint8Array(await file.slice(0, 65536).arrayBuffer()))
  range.requestDataRange = (begin, end) => {
    file.slice(begin, end).arrayBuffer().then((buffer) => range.onDataRange(begin, new Uint8Array(buffer)))
  }
  return { range, disableAutoFetch: true, disableStream: true }
}

async function renderCover(pdf) {
  const page = await pdf.getPage(1)
  const unscaled = page.getViewport({ scale: 1 })
  const viewport = page.getViewport({ scale: COVER_SIZE / Math.max(unscaled.width, unscaled.height) })
  const canvas = document.createElement("canvas")
  canvas.width = Math.round(viewport.width)
  canvas.height = Math.round(viewport.height)
  const context = canvas.getContext("2d")
  context.fillStyle = "#fff" // pages without a background would turn black as JPEG
  context.fillRect(0, 0, canvas.width, canvas.height)
  await page.render({ canvasContext: context, viewport }).promise
  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => blob ? resolve(blob) : reject(new Error("canvas is empty")), "image/jpeg", 0.8)
  })
}

// Names like "رنگين_تنهائي-منصور_سيتائي-2016-صاف.pdf" or
// "Dadabhai_Naoroji_The_Grand_Old_Man_of_India--R_P_Masani_(1939)_ocr.pdf":
// title, then author, then the year, alone between dashes or in brackets.
// A year inside the title ("Pakistan_1969_1971") is part of the title.
function fileNameParts(name) {
  return name.replace(/\.[^.]+$/, "").replace(/_/g, " ").split(/-+/)
    .map((part) => part.replace(new RegExp(`\\s*\\(${YEAR}\\).*$`), "").trim())
    .filter((part) => part && !new RegExp(`^${YEAR}ع?$`).test(part) && !/^(صاف|ocr|cs)$/i.test(part))
}

function fileNameYear(name) {
  const bracketed = [...name.matchAll(new RegExp(`\\(${YEAR}\\)`, "g"))].pop()
  const alone = [...name.matchAll(new RegExp(`(?:^|-)${YEAR}ع?(?=[-.]|$)`, "g"))].pop()
  const anywhere = [...name.matchAll(new RegExp(`(?<!\\d)${YEAR}(?!\\d)`, "g"))].pop()
  return (bracketed || alone || anywhere)?.[1]
}

// Only for what the PDF itself did not say.
function fillFromFileName(form, name) {
  const [title, author] = fileNameParts(name)
  fillByScript(form, title, "name", "name_eng")
  fillByScript(form, author, "author_sindhi", "author")
  fill(form, "language", guessLanguage(title))
}

// From a title's letters: only a guess, so it is marked for checking too.
function guessLanguage(text) {
  if (!text) return null
  if (SINDHI_LETTERS.test(text)) return "Sindhi"
  if (URDU_LETTERS.test(text)) return "Urdu"
  if (/^[\p{Script=Latin}\p{N}\p{P}\s]+$/u.test(text)) return "English"
  return null
}

// Arabic-script text goes in the Sindhi field: most PDFs carry no language.
function fillByScript(form, text, sindhiField, englishField) {
  if (text) fill(form, ARABIC.test(text) ? sindhiField : englishField, text)
}

// Fills a field only if it is empty, and marks it for checking.
function fill(form, attribute, value) {
  const field = form.elements[`book[${attribute}]`]
  if (!value || !field || field.value.trim()) return
  field.value = value
  field.classList.add("autofilled")
  form.querySelector("[data-autofill-note]").hidden = false
}

function clean(value) {
  const text = (Array.isArray(value) ? value.join(", ") : String(value ?? ""))
    .replace(/^Microsoft Word - /, "").replace(/\s+/g, " ").trim()
  return /^untitled$/i.test(text) ? "" : text
}

function directUpload(url, file, onProgress) {
  return new Promise((resolve, reject) => {
    const delegate = {
      directUploadWillStoreFileWithXHR(xhr) {
        xhr.upload.addEventListener("progress", (event) => onProgress?.(event.loaded / event.total))
      },
    }
    new DirectUpload(file, url, delegate).create((error, blob) => error ? reject(error) : resolve(blob.signed_id))
  })
}

// Counts running uploads; the save button waits for them.
function track(form, promise) {
  const change = (delta) => {
    const pending = (Number(form.dataset.pending) || 0) + delta
    form.dataset.pending = pending
    form.querySelectorAll("[type=submit]").forEach((button) => { button.disabled = pending > 0 })
  }
  change(1)
  return promise.finally(() => change(-1))
}

// Added after the file input, so for book[attachment] it wins over a file
// kept from a failed save.
function setField(form, name, value) {
  let field = form.querySelector(`input[data-js-field="${name}"]`)
  if (!field) {
    field = Object.assign(document.createElement("input"), { type: "hidden", name })
    field.dataset.jsField = name
    form.append(field)
  }
  field.value = value
}

// null hides it; a fraction shows the bar; "done" and "failed" say so.
function showProgress(form, state) {
  const box = form.querySelector("[data-upload]")
  const bar = box.querySelector("progress")
  const label = box.querySelector("[data-upload-label]")
  box.hidden = state === null
  box.classList.toggle("text-error", state === "failed")
  if (typeof state === "number") {
    bar.hidden = false
    bar.value = state
    label.textContent = `${box.dataset.uploading} ${Math.round(state * 100)}%`
  } else if (state) {
    bar.hidden = true
    label.textContent = box.dataset[state]
  }
}
