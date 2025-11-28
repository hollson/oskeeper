#import "@preview/minimal-presentation:0.7.0": *

#set text(font: "Helvetica Neue")
#show raw: set text(font: "Cartograph CF")

#show: project.with(
  title: "Minimalist presentation template",
  sub-title: "This is where your presentation begins",
  author: "Flavio Barisi",
  date: "10/08/2023",
  index-title: "Contents",
  logo: image("templates/images/acias-logo.png"),
  // logo-light: image("templates/images/acias-logo.png"),
  main-color: rgb("#00AEEF"),
  lang: "en",
)

= This is a section

== This is a slide title

#lorem(10)

- #lorem(10)
  - #lorem(10)
  - #lorem(10)
  - #lorem(10) 


== One column image

#figure(
  image("templates/images/acias-logo.png"),
  caption: [An image],
) <image_label>

== Two columns image

#columns-content()[
  #figure(
    image("templates/images/acias-logo.png", width: 100%),
    caption: [An image],
  ) <image_label_1>
][
  #figure(
    image("templates/images/acias-logo.png", width: 100%),
    caption: [An image],
  ) <image_label_2>
]

== Two columns

#columns-content()[
  - #lorem(10)
  - #lorem(10)
  - #lorem(10)
][
  #figure(
    image("templates/images/acias-logo.png", width: 100%),
    caption: [An image],
  ) <image_label_3>
]

= This is a section

== This is a slide title

#lorem(10)

= This is a section

== This is a slide title

#lorem(10)

= This is a section

== This is a slide title

#lorem(10)

= This is a very v v v v v v v v v v v v v v v v v v v v  long section

== This is a very v v v v v v v v v v v v v v v v v v v v  long slide title

= Subtitle test

== Slide title

#lorem(50)

=== Slide subtitle 1

#lorem(50)

=== Slide subtitle 2

#lorem(50)

== Slide title 2

#lorem(50)

=== Slide subtitle 3

#lorem(50)

=== Slide subtitle 4

#lorem(50)

#set-main-color(blue)

= You can change color

== Slide title

#lorem(50)