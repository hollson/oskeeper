#import "templates/template.typ": project, title-page, contents-page, section-page, with-page-numbering, acias-table, kbd

#show: project

#title-page(
  title: [Project - SAMPLE],
  subtitle: [Deployment Docs],
  version: [version 1.0],
  author: [Thu Yein],
  date: [November 2025],
)

#contents-page("Table of Contents")

#show: with-page-numbering

= Tables

== Acias Table format (subheading)
#acias-table(
  caption: [Server Serial list],
  ([Name], [Serial Number]),

  [Sender 1], [x],
  [Sender 2], [x],
  [Receiver 1], [x],
  [Receiver 2], [x],
)


= Images

// #figure(
//   image("images/HPE-labelled.png"),
//   caption: [
//     server rear diagram
//   ]
// )

#pagebreak()

= Keyboard Icons 🥳

#kbd("cmd")
#kbd("ctrl")
#kbd("shift")
#kbd("option")
#kbd("enter")
#kbd("tab")
#kbd("delete")
#kbd("esc")
#kbd("up")
#kbd("down")
#kbd("left")
#kbd("right")
#kbd("space")

= Lists

- a
- b

= Numbered Lists

+ a
+ b
