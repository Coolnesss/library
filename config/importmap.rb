# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "nav"
pin "tags"
pin "search"
# The book form's upload (book_form.js) only: fetched on that page, not preloaded everywhere.
pin "book_form", preload: false
pin "@rails/activestorage", to: "activestorage.esm.js", preload: false
# pdf.js 4.10.38 (Apache-2.0, vendor/assets/javascripts), with its worker
# loaded by URL from book_form.js.
pin "pdfjs", to: "pdfjs.js", preload: false
