# Getting Started

`pattern-library` is a package of SASS specifications intended to allow you to
style your web page elements to conform with the OpenStax design [here](https://sketchviewer.com/sketches/59766aabb57e8900114c89ce/latest/).

The pattern-library is built on mixins and placeholders so that you do not have to
use the particular classes used in the `elements` module. You can simply
`@import headers` from the pattern library and then define your styles in terms
of `@extend`s and `@include`s, as well as using the numerous variables. This is
useful if you need to retrofit styles to existing code and don't happen to have
used the same class names as I decided on.

If you are writing from scratch, you might want to `@import elements` which has
classname based specifications ready to use. If not, it may be useful to refer
to it for how to set up your specs.
