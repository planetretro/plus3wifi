border 0 : paper 0 : ink 9 : clear 32727

@_start:
  cls
  print inverse 1; "p3prtwifi Main Menu" : print

  print inverse 1; "0"; inverse 0; " WiFi Config"
  print inverse 1; "1"; inverse 0; " Load uGophy"
  print inverse 1; "2"; inverse 0; " Load debug tool"

@_waitKey:
  pause 0
  let i$ = inkey$
  if i$="0" then gosub @_config : goto @_start
  if i$="1" then let f$="ugoph.bas" : goto @_loader
  if i$="2" then let f$="debug.bas" : goto @_loader
  goto @_waitKey

@_config:
  cls
  print inverse 1; "p3prtwifi WiFi Config" : print

  let dest=32768
  for i=0 to 159
    poke dest+i, 0
  next i

@_loop:
print inverse 1;"Enter SSID"
input line a$
print a$
print inverse 1;"Enter Password"
input line b$
print b$

print : print "Is this correct? y/n"
pause 0
let i$=inkey$
if i$ <> "y" then goto @_loop

print : print "Saving IW.CFG..."

for i=0 to len(a$)-1
  poke dest+i, code (a$(i+1))
next i

for i=0 to len(b$)-1
  poke dest+80+i, code (b$(i+1))
next i

save "iw.cfg" code dest, 160
print : print "All done!"
pause 100 : return

@_loader:
  cls
  print inverse 1; "Loading " + f$ + "..."
  load f$

