// template.typ

#let theme-colour = rgb("#00AEEF")

// Title page function
#let title-page(
  title: none,
  subtitle: none,
  author: none,
  version: none,
  date: none,
) = {
  set page(numbering: none)
  align(center + horizon)[
    #text(size: 30pt, weight: "semibold")[#title]

    #if subtitle != none [
      #text(size: 14pt)[#subtitle]
    ]

    #if author != none or date != none [
      #v(5em)
      #text(size: 10pt)[
        #if author != none [#author]
        #if author != none and date != none [#v(0.5em)]
        #if date != none [#date]
      ]
    ]

    #if version != none [
      #text(size: 10pt)[#version]
    ]
  ]
  pagebreak()
}

#let contents-page(title) = {
  align(center)[
    #text(size: 16pt, weight: "semibold")[#title]
  ]
  v(2em)

  outline(
    title: none,
    indent: n => n * 1em,  // 1em per level (customize the multiplier)
  )
  pagebreak()
}

// Section page function
#let section-page(title) = {
  pagebreak()
  align(center + horizon)[
    #text(size: 22pt, weight: "semibold")[#title]
  ]
  pagebreak()
}

#let with-page-numbering(body) = {
  set page(numbering: "1")
  counter(page).update(1)
  body
}

// Main template function
#let project(body) = {
  set page(
    margin: (
      top: 3cm,
      bottom: 2cm,
      left: 3.5cm,
      right: 2cm,
    ),

    // header for the addresses
    header: [
      #set text(size: 6pt, weight: "semibold", fill: theme-colour)
      #grid(
        columns: (1fr, 1fr, 1fr),
        align: (left, top+center, top+right),
        column-gutter: 1em,
        [
          21 Tan Quee Lan Street\
          \#02-04 Heritage Place \
          Singapore 188108
        ],
        [
          T: +65 80443781\
          contact_acias\@acias.co
        ],
        [
          UEN: 202211187D
        ],
      )
    ],
    // page footer but skip title page and contents page
    footer: context [
      #let page-numbering = page.numbering
      #if page-numbering != none [
        #set text(size: 6pt, weight: "semibold", fill: theme-colour)
        #align(right)[
          PAGE #counter(page).display() OF #counter(page).final().first()
        ]
      ]

      // add website to the bottom left
      #set text(size: 6pt, weight: "semibold", fill: theme-colour)
      #place(bottom + left, dx: -2cm, dy:-1.2cm)[
        acias.co
      ]
    ],

    // aegis logo on the left side
    background: [
      #place(
        top + left,
        dx: 1cm,
        dy: 1cm,
        image("images/acias-logo-rotated.png", width: 1.0cm)
      )
    ]
  )

  // font family
  set text(font: "Helvetica Neue")
  // enable numbering of the sections
  set heading(numbering: "1.")
  // set code font family
  show raw: set text(font: "Cartograph CF")
  set par(
    leading: 1.3em,
    spacing: 2em,        // Space between paragraphs
  )
  // Add spacing before & after headings
  show heading: it => {
    v(1em)
    it
    v(1em)
  }

  body
}


#let acias-table(
  caption: none,
  headers,
  ..cells
) = {
  align(center)[
    #figure(
      table(
        table.header(
          ..headers.map(h => [#text(fill: white, weight: "bold")[#h]])
        ),
        fill: (x, y) => if y == 0 { theme-colour } else if calc.rem(y, 2) == 0 { rgb(240, 240, 255) },
        columns: headers.map(_ => 1.5fr),
        stroke: 0.5pt,
        inset: 8pt,
        align: center,
        ..cells
      ),
      caption: caption
    )
  ]
}

// // equivalent to <kbd> tag in markdown
// Usage: #kbd("cmd") + #kbd("k")
#let kbd(key) = {
  let key-icons = (
    "cmd": "⌘",
    "command": "⌘",
    "ctrl": "⌃",
    "control": "⌃",
    "shift": "⇧",
    "alt": "⌥",
    "option": "⌥",
    "enter": "↵",
    "return": "↵",
    "tab": "⇥",
    "delete": "⌫",
    "backspace": "⌫",
    "esc": "⎋",
    "escape": "⎋",
    "up": "↑",
    "down": "↓",
    "left": "←",
    "right": "→",
    "space": "␣",
  )

  let key-str = str(key).trim()
  let display = key-icons.at(key, default: key)

  box(
    fill: rgb(240, 240, 240),
    stroke: 0.5pt + rgb(180, 180, 180),
    inset: (x: 6pt, y: 3pt),
    radius: 3pt,
    baseline: 20%,
    [#text(size: 0.9em, font: "SF Pro Display", weight: "regular")[#display]]
  )
}
