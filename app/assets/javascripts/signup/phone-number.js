/* This script is based on the javascript code of Roman Feldblum (web.developer@programmer.net) */
/* Original script : http://javascript.internet.com/forms/format-phone-number.html */
/* Original script is revised by Eralper Yilmaz (http://www.eralper.com) */
/* Revised script : http://www.kodyaz.com */

var zChar = new Array(' ', '(', ')', '-', '.');
var maxphonelength = 13;
var phonevalue1;
var phonevalue2;
var cursorposition;

function ParseForNumber1(object) {
  phonevalue1 = ParseChar(object.value, zChar);
}

function ParseForNumber2(object) {
  phonevalue2 = ParseChar(object.value, zChar);
}

function isUSA() {
  /* Testing for USA because this formatting JS is USA format only. The   */
  /* iti__ selector is from the intlTelInput plugin (a coupling)          */
  if ( $('#login-signup-form .iti__selected-flag').attr( "title") === "United States: +1" ) {
    return true
  }
  else {
    return false
  }
}

function backspacerUP(object, e) {
  if ( !isUSA() ) {
    return true;
  }

  if (e) {
    e = e
  } else {
    e = window.event
  }
  if (e.which) {
    var keycode = e.which
  } else {
    var keycode = e.keyCode
  }

  ParseForNumber1(object)

  if (keycode >= 48) {
    ValidatePhone(object)
  }
}

function backspacerDOWN(object, e) {
  if ( !isUSA() ) {
    return true;
  }

  if (e) {
    e = e
  } else {
    e = window.event
  }
  if (e.which) {
    var keycode = e.which
  } else {
    var keycode = e.keyCode
  }

  ParseForNumber2(object)
}

function GetCursorPosition() {

  var t1 = phonevalue1;
  var t2 = phonevalue2;
  var bool = false
  for (i = 0; i < t1.length; i++) {
    if (t1.substring(i, 1) != t2.substring(i, 1)) {
      if (!bool) {
        cursorposition = i
        bool = true
      }
    }
  }
}

function ValidatePhone(object) {

  var p = phonevalue1

  p = p.replace(/[^\d]*/gi, "")

  if (p.length < 3) {
    object.value = p
  } else if (p.length == 3) {
    pp = p;
    d4 = p.indexOf('(')
    d5 = p.indexOf(')')
    if (d4 == -1) {
      pp = "(" + pp;
    }
    if (d5 == -1) {
      pp = pp + ")";
    }
    object.value = pp;
  } else if (p.length > 3 && p.length < 7) {
    p = "(" + p;
    l30 = p.length;
    p30 = p.substring(0, 4);
    p30 = p30 + ")"

    p31 = p.substring(4, l30);
    pp = p30 + p31;

    object.value = pp;

  } else if (p.length >= 7) {
    p = "(" + p;
    l30 = p.length;
    p30 = p.substring(0, 4);
    p30 = p30 + ")"

    p31 = p.substring(4, l30);
    pp = p30 + p31;

    l40 = pp.length;
    p40 = pp.substring(0, 8);
    p40 = p40 + "-"

    p41 = pp.substring(8, l40);
    ppp = p40 + p41;

    object.value = ppp.substring(0, maxphonelength);
  }

  GetCursorPosition()

  if (cursorposition >= 0) {
    if (cursorposition == 0) {
      cursorposition = 2
    } else if (cursorposition <= 2) {
      cursorposition = cursorposition + 1
    } else if (cursorposition <= 5) {
      cursorposition = cursorposition + 2
    } else if (cursorposition == 6) {
      cursorposition = cursorposition + 2
    } else if (cursorposition == 7) {
      cursorposition = cursorposition + 4
      e1 = object.value.indexOf(')')
      e2 = object.value.indexOf('-')
      if (e1 > -1 && e2 > -1) {
        if (e2 - e1 == 4) {
          cursorposition = cursorposition - 1
        }
      }
    } else if (cursorposition < 11) {
      cursorposition = cursorposition + 3
    } else if (cursorposition == 11) {
      cursorposition = cursorposition + 1
    } else if (cursorposition >= 12) {
      cursorposition = cursorposition
    }

    if (document.selection) { //IE
      var range = object.createTextRange();
      range.moveStart("character", cursorposition);
      range.moveEnd("character", cursorposition - object.value.length);
      range.select();
    } else if (window.getSelection) { //others
      var range = document.createRange();
      range.selectNode(document.getElementById(object.id)); //todo fix this for cursorposition
      window.getSelection().addRange(range);
    }
  }
}

function ParseChar(sStr, sChar) {
  if (sChar.length == null) {
    zChar = new Array(sChar);
  } else zChar = sChar;

  for (i = 0; i < zChar.length; i++) {
    sNewStr = "";

    var iStart = 0;
    var iEnd = sStr.indexOf(sChar[i]);

    while (iEnd != -1) {
      sNewStr += sStr.substring(iStart, iEnd);
      iStart = iEnd + 1;
      iEnd = sStr.indexOf(sChar[i], iStart);
    }
    sNewStr += sStr.substring(sStr.lastIndexOf(sChar[i]) + 1, sStr.length);

    sStr = sNewStr;
  }

  return sNewStr;
}
