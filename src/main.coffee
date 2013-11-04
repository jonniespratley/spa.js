# spa main 

# Base object.
Spa = ->
  new spa()  unless this instanceof spa


# Version.
spa.VERSION = "0.0.0"

# Export to the root, which is probably `window`.
root.spa = Spa