(function(root, undefined) {

  "use strict";


/* spa main */

// Base object.
var Spa = function() {
  if (!(this instanceof spa)) {
    return new spa();
  }
};


// Version.
spa.VERSION = '0.0.0';


// Export to the root, which is probably `window`.
root.spa = Spa;


}(this));
