globals [
  punch-damage
  kick-damage
  jump-kick-damage
  flying-punch-damage
  spin-kick-damage
  score
  game-start?
  game-over?
]

breed [warriors warrior]
breed [badguys badguy]

directed-link-breed [grappling-hook-vectors grappling-hook-vector]

turtles-own [
  health
  crouching?
]

badguys-own [
  strategy        ;text that indicates what the badguys current strategy is
  strategy-timer  ;a timer that counts down before the strategy is cleared
]

warriors-own [
  move1 ;these track a history of moves to be used for cheat codes (think left left right right up down up down a b b a)
  move2
  move3
  move4
  move5
  move6
  move7
  move8
  move9
  move10
  move11
  move12
]

to setup
  clear-all
  clear-output
  clear-patches
  clear-turtles
  reset-ticks

  set game-start? true
  set game-over? false

  ;generate floor
  ask patches with [pycor = -16] [
    set pcolor brown
  ]

  ;setup damage amounts
  set punch-damage 1
  set kick-damage 2
  set jump-kick-damage 3
  set flying-punch-damage 3
  set spin-kick-damage 2

  ;init score
  set score 0

  ;generate fighters
  create-warriors 1 [
    set shape "warrior"
    set health 20
    setxy -28 -8
    set size 15
    set heading 90
    set move1 ""
    set move2 ""
    set move3 ""
    set move4 ""
    set move5 ""
    set move6 ""
    set move7 ""
    set move8 ""
    set move9 ""
    set move10 ""
    set move11 ""
    set move12 ""
    set crouching? false
  ]

  create-badguys 1 [
    set strategy ""
    set strategy-timer 0
    set shape "badguy"
    set health 20
    setxy 28 -8
    set size 15
    set heading 270
    set crouching? false
  ]

  update-screen


end

to fight

  ;starting graphics
  if game-start? = true [
    ask patch 1 13 [
      set plabel-color yellow
      set plabel "Ready!"
      wait 2
      set plabel "Fight!"
      wait random 2 + 0.5
      set plabel ""
    ]

    set game-start? false
  ]



  ;determine what badguy will do
  if ticks mod 50 = 0 and [health > 0] of one-of warriors and not game-over? [

    ;pick a random number
    let badguy-action random 10 + 1



    ;set the strategy to backing up if badguy is too close and he's not already backing up
    ask one-of badguys with [health > 0] [

      ;check for a chance to use badguy's grappling hook
      if random 100 + 1 = 1 and [health < 20] of one-of warriors [
        set strategy "grappling hook"
        set strategy-timer 30
      ]

      ;if there's a lot of distance between the two, and there has already been some fighting, there is an increase change of using the grappling hook
      if distance one-of warriors >= 25 and random 10 >= 6 and [health < 20] of one-of warriors [
        set strategy "grappling hook"
        set strategy-timer 30
      ]


      ;attack if in fighting range
      if distance one-of warriors <= 10 [
        ifelse random 10 + 1 >= 5 [set badguy-action 7][set badguy-action 8]
      ]

      ;start backing up
      if distance one-of warriors <= 5 and strategy-timer = 0 [
        set strategy "backup"
        set strategy-timer random 7 + 3
        set badguy-action 99
      ]

      ;continue backing up
      if strategy = "backup" and strategy-timer > 0 [
        set badguy-action 99
        set strategy-timer strategy-timer - 1
      ]

      ;grappling hook strategy.  attempt to create distance and then throw the hook
      if strategy = "grappling hook" and strategy-timer > 0 [
        ifelse distance one-of warriors < 25 [
          set badguy-action 99
          set strategy-timer strategy-timer - 1
        ][
          badguy-grappling-hook
        ]
      ]


      ]

    ;walk
    if badguy-action >= 1 and badguy-action <= 6 [
      ask one-of badguys [
        ifelse health >= 5 [
          badguy-walk-toward-warrior
        ][
          badguy-random-walk
        ]
      ]
    ]

    ;punch
    if badguy-action = 7 [
      ask one-of badguys [
        if any? warriors in-radius 12 [badguy-punch]
      ]
    ]

    ;kick
    if badguy-action = 8 [
      ask one-of badguys [
        ifelse random 10 + 1 >= 7 [
          if any? warriors in-radius 12 [badguy-kick]
        ][
          if any? warriors in-radius 15 [badguy-jump-kick]
        ]
      ]
    ]

    ;backup
    if badguy-action = 99 [
      ask one-of badguys [
        badguy-right-walk
      ]
    ]

    reset-ticks

  ]

  update-screen


  ;check for deaths
  check-for-death


  if not game-over? [tick]


end

to check-for-death

  ask badguys [
    if health <= 0 [
      ;user-message "You Win!"
      set shape "badguy-knockout"
      set game-over? true
      stop
    ]
  ]

  ask warriors [
    if health <= 0 [
      ;user-message "You loose!"
      set shape "warrior-knockout"
      set game-over? true
      stop
    ]
  ]
end

to update-screen

  if not game-over? [
    ;update warrior health bar
    ;start by drawing red bar, then follow it up with green for health
    let display-cursor-x -32
    let display-cursor-y 13
    repeat 20 [
      ask patch display-cursor-x display-cursor-y [set pcolor red]
      set display-cursor-x display-cursor-x + 1
    ]

    ;reset x cursor and draw green for health
    set display-cursor-x -32
    repeat [health] of one-of warriors [
      ask patch display-cursor-x display-cursor-y [set pcolor green]
      set display-cursor-x display-cursor-x + 1
    ]


    ;update badguy health bar
    set display-cursor-x 32
    repeat 20 [
      ask patch display-cursor-x display-cursor-y [set pcolor red]
      set display-cursor-x display-cursor-x - 1
    ]

    ;reset x cursor and draw green for health
    set display-cursor-x 32
    repeat [health] of one-of badguys [
      ask patch display-cursor-x display-cursor-y [set pcolor green]
      set display-cursor-x display-cursor-x - 1
    ]

    ;update score
    ask patch -20 15 [
      set plabel (word "SCORE: " score)
      set plabel-color yellow
    ]
  ]

  if game-over? = true [
    if [shape = "badguy-knockout"] of one-of badguys [
      ask one-of warriors [set shape "warrior-victory"]
    ]

    if [shape = "warrior-knockout"] of one-of warriors [
      ask one-of badguys [set shape "badguy-victory"]
    ]
  ]

end

to update-move-chain [new-move]

  ;this tracks the last 12 moves.  This is used for cheat codes and special combo moves
  ask one-of warriors [

    set move12 move11
    set move11 move10
    set move10 move9
    set move9 move8
    set move8 move7
    set move7 move6
    set move6 move5
    set move5 move4
    set move4 move3
    set move3 move2
    set move2 move1
    set move1 new-move
  ]

end



;************
;warrior moves
;************

to warrior-crouch
  if not game-over? [
    update-move-chain "warrior-crouch"

    ask one-of warriors [
      if not crouching? [
        set shape "warrior-crouch"
        set heading 180
        fd 4
        set crouching? true
      ]
    ]

  ]
end

to warrior-stand
  if not game-over? [
    update-move-chain "warrior-stand"

    ask one-of warriors [
      if crouching? [
        set shape "warrior"
        set crouching? false
        set heading 0
        fd 4
      ]
    ]

  ]
end


to right-walk


  if not game-over? [
    update-move-chain "right-walk"

    if any? warriors with [crouching? = false] [

      ask one-of warriors [
        set heading 90
        set shape "warrior-walk1"
        fd 1
      ]

      wait 0.1

      ask one-of warriors [
        set shape "warrior-walk2"
        fd 1
      ]

      wait 0.1

      ask one-of warriors [
        set shape "warrior"
      ]
    ]
  ]
end

to left-walk

  if not game-over? [
    update-move-chain "left-walk"

    if any? warriors with [crouching? = false] [

      ask one-of warriors [
        set heading 270
        set shape "warrior-walk1"
        fd 1
      ]

      wait 0.1

      ask one-of warriors [
        set shape "warrior-walk2"
        fd 1
      ]

      wait 0.1

      ask one-of warriors [
        set shape "warrior"
      ]
    ]
  ]

end

to warrior-flying-punch
;this is a combo move.
  if not game-over? [

    if any? warriors with [crouching? = false] [

      update-move-chain "warrior-flying-punch"

      wait 0.1

      ask one-of warriors [
        set heading 45
        fd 3
        set shape "warrior-flying-punch"
        wait 0.15
        fd 2
        set heading 90
        fd 1
        set heading 0
        set shape "warrior-flying-punch2"

         if any? badguys in-radius 10 with [health > 0] [

          ifelse random 10 > 5 [

            ;hit
            ask badguys [
              set size size + 5
              wait 0.2
              set size size - 5
              set heading 90
              repeat random 25 + 5 [
                fd 1
                wait 0.1
              ]
              set heading 270
              set health health - flying-punch-damage
            ]
            set score score + (flying-punch-damage * 100)

          ][
            ;miss
            ask badguys [
              set shape "badguy-block"
              wait 0.4
              set shape "badguy"
            ]
          ]
        ]

        repeat 8 [
          fd 1
          wait 0.05
        ]

        set heading 180
        fd 2
        wait 0.15
        set heading 135
        fd 1
        set shape "warrior-jump-kick1"
        set heading 180
        repeat 8 [
          fd 1
          wait 0.05
        ]

        set heading 90

      ]



      wait 0.25

      ask one-of warriors [
        set shape "warrior"
        set ycor -8
      ]

      update-screen
      check-for-death
    ]
  ]

end

to warrior-spin-kick

  ;this is a combo move

  if not game-over? [

    if any? warriors with [crouching? = false] [

      update-move-chain "warrior-spin-kick"

      wait 0.1

      ask one-of warriors [
        set heading 45
        fd 2
        set shape "warrior-jump-kick1"
        wait 0.15
        fd 2
        repeat random 7 + 3 [
          set shape "warrior-spin-kick-right"
          set heading 90
          fd 2

          ;check to see if badguy is hit
          if any? badguys in-radius 10 with [health > 0] [

            ifelse random 10 > 5 [

              ;hit
              ask badguys [
                set size size + 5
                wait 0.2
                set size size - 5
                set health health - spin-kick-damage
              ]
              set score score + (spin-kick-damage * 100)
            ][
              ;miss
              ask badguys [
                set shape "badguy-block"
                wait 0.4
                set shape "badguy"
              ]
            ]
          ]
          wait 0.15
          set shape "warrior-spin-kick-left"
          wait 0.15
        ]



        wait 0.1
        set heading 135
        fd 1
        set shape "warrior-jump-kick1"
        set heading 180
        fd 2
        set heading 90

      ]



      wait 0.25

      ask one-of warriors [
        set shape "warrior"
        set ycor -8
      ]

      update-screen
      check-for-death
    ]
  ]
end


to warrior-jump-kick

  ;this is a combo move.  To do you you go left, right then kick

  if not game-over? [

    if any? warriors with [crouching? = false] [

      update-move-chain "warrior-jump-kick"

      wait 0.1

      ask one-of warriors [
        set heading 45
        fd 2
        set shape "warrior-jump-kick1"
        wait 0.15
        fd 2
        set shape "warrior-jump-kick2"
        set heading 90
        fd 2
        wait 0.15

        if any? badguys in-radius 10 with [health > 0] [

          ifelse random 10 > 5 [

            ;hit
            ask badguys [
              set size size + 5
              wait 0.2
              set size size - 5
              set heading 90
              repeat random 15 + 5 [
                fd 1
                wait 0.1
              ]
              set heading 270
              set health health - jump-kick-damage
            ]
            set score score + (jump-kick-damage * 100)

          ][
            ;miss
            ask badguys [
              set shape "badguy-block"
              wait 0.4
              set shape "badguy"
              ifelse random 10 >= 5 [badguy-kick][badguy-punch]
            ]
          ]
        ]

        wait 0.1
        set heading 135
        fd 1
        set shape "warrior-jump-kick1"
        set heading 180
        fd 2
        set heading 90

      ]



      wait 0.25

      ask one-of warriors [
        set shape "warrior"
        set ycor -8
      ]

      update-screen
      check-for-death
    ]
  ]
end

to warrior-kick

  if not game-over? [
    if any? warriors with [crouching? = false] [
      update-move-chain "warrior-kick"

      ask one-of warriors [
        ;check for combo moves first
        if move1 = "warrior-kick" and move2 = "warrior-stand" and move3 = "left-walk" and move4 = "warrior-crouch" [warrior-spin-kick stop]
        if move1 = "warrior-kick" and move2 = "right-walk" and move3 = "left-walk" [warrior-jump-kick stop]


        ;regular kick

        wait 0.05

        ask one-of warriors [
          set shape "warrior-kick1"
          wait 0.1
          set shape "warrior-kick2"

          if any? badguys in-radius 10 with [health > 0] [

            ifelse random 10 > 5 [

              ;hit
              ask badguys [
                set size size + 5
                wait 0.2
                set size size - 5
                set heading 90
                fd 1
                wait 0.1
                set heading 270
                set health health - kick-damage
              ]
              set score score + (kick-damage * 100)

            ][
              ;miss
              ask badguys [
                set shape "badguy-block"
                wait 0.2
                set shape "badguy"
              ]
            ]
          ]

          wait 0.2
          set shape "warrior-kick1"

        ]



        wait 0.2

        ask one-of warriors [
          set shape "warrior"
        ]

        update-screen
        check-for-death
      ]
    ]
  ]
end

to warrior-punch

  if not game-over? [
    if any? warriors with [crouching? = false] [
      update-move-chain "warrior-punch"
      wait 0.1

      ask one-of warriors [
        ;check for flying punch first
        ifelse move1 = "warrior-punch" and move2 = "warrior-stand" and move3 = "right-walk" and move4 = "warrior-crouch" [
          warrior-flying-punch
        ][
          set shape "warrior-punch"



          if any? badguys in-radius 8 with [health > 0] [
            ifelse random 10 > 5 [
              ask badguys [
                set size size + 5
                wait 0.2
                set size size - 5
                set heading 90
                fd 0.5
                wait 0.1
                set heading 270
                set health health - punch-damage
              ]
              set score score + (punch-damage * 100)
            ][

              ;miss
              ask badguys [
                set shape "badguy-punch-block"
                wait 0.4
                set shape "badguy"
              ]
            ]
          ]
        ]
      ]



      wait 0.2

      ask one-of warriors [
        set shape "warrior"
      ]

      update-screen
      check-for-death
    ]
  ]
end




;*************
;badguy moves
;*************

to badguy-grappling-hook
   wait 0.1

  ask one-of badguys [
    set shape "badguy-kick1"
    wait 0.25
    set shape "badguy-punch"


    ;throw hook
    ask one-of badguys [
      create-grappling-hook-vector-to one-of warriors
      ask grappling-hook-vectors [
        set color red
        set thickness 0.25
      ]
      wait 0.5
      set shape "badguy-kick1"
      wait 0.2


      ;reel in the warrior
      repeat ((distance one-of warriors * 2) - 10) [
        ask one-of warriors [
          set heading 90
          fd 0.5
          wait 0.02
        ]
      ]

      ;disappear grappling hook
      ask grappling-hook-vectors [die]

      ;now beat him up a bit
      ;some random number of punches
      repeat random 8 + 2 [
        if [health > 0] of one-of warriors [
          badguy-punch
        ]
      ]

      ;a few kicks for good measure
      repeat random 5 + 2 [
        if [health > 0] of one-of warriors [
          badguy-kick
        ]
      ]

      ;and a final jump kick
      if [health > 0] of one-of warriors [badguy-jump-kick]


      ask grappling-hook-vectors [die]
    ]

    set shape "badguy-kick1"

  ]



  wait 0.25

  ask one-of badguys [
    set shape "badguy"
  ]

  update-screen
  check-for-death

end


to badguy-jump-kick

  if not game-over? [

    wait 0.1

    ask one-of badguys [
      set heading 315
      fd 2
      set shape "badguy-kick1"
      wait 0.15
      fd 2
      set shape "badguy-jump-kick"
      set heading 270
      fd 2
      wait 0.15

      if any? warriors in-radius 10 with [health > 0] [

        ifelse random 10 > 5 [

          ;hit
          ask warriors [
            set size size + 5
            wait 0.2
            set size size - 5
            set heading 270
            repeat random 15 + 5 [
              fd 1
              wait 0.1
            ]
            set heading 90
            set health health - jump-kick-damage
          ]
          set score score + (jump-kick-damage * 100)

        ][
          ;miss
          ask warriors [
            set shape "warrior-block"
            wait 0.4
            set shape "warrior"
          ]
        ]
      ]

      wait 0.1
      set heading 225
      fd 1
      set shape "badguy-kick1"
      set heading 180
      fd 2
      set heading 270

    ]



    wait 0.25

    ask one-of badguys [
      set shape "badguy"
      set ycor -8
    ]

    update-screen
    check-for-death
  ]
end

to badguy-punch

  wait 0.1

  ask one-of badguys [
    set shape "badguy-punch"

    if any? warriors in-radius 8 [
      ask warriors [
        set size size + 5
        wait 0.2
        set size size - 5
        set heading 270
        fd 0.5
        wait 0.1
        set heading 90
        set health health - punch-damage
      ]
    ]
  ]



  wait 0.2

  ask one-of badguys [
    set shape "badguy"
  ]

  update-screen
  check-for-death


end

to badguy-kick

  wait 0.1

  ask one-of badguys [
    set shape "badguy-kick1"
    wait 0.25
    set shape "badguy-kick2"


    if any? warriors in-radius 10 [

      ifelse random 10 > 5 [

        ;hit
        ask warriors [
          set size size + 5
          wait 0.2
          set size size - 5
          set heading 270
          fd 1
          wait 0.1
          set heading 90
          set health health - kick-damage
        ]


      ][
        ;miss
        ask warriors [
          set shape "warrior-block"
          wait 0.4
          set shape "warrior"
        ]
      ]



    ]

    wait 0.1
    set shape "badguy-kick1"

  ]



  wait 0.25

  ask one-of badguys [
    set shape "badguy"
  ]

  update-screen
  check-for-death

end

to badguy-right-walk
  ask one-of badguys [
    set heading 90
    set shape "badguy-walk1"
    fd 1
  ]

  wait 0.1

  ask one-of badguys [
    set shape "badguy-walk2"
    fd 1
  ]

  wait 0.1

  ask one-of badguys [
    set shape "badguy"
  ]
end

to badguy-left-walk
  ask one-of badguys [
    set heading 270
    set shape "badguy-walk1"
    fd 1
  ]

  wait 0.1

  ask one-of badguys [
    set shape "badguy-walk2"
    fd 1
  ]

  wait 0.1

  ask one-of badguys [
    set shape "badguy"
  ]
end

to badguy-random-walk
  ifelse random 10 > 5 [badguy-right-walk][badguy-left-walk]
end

to badguy-walk-toward-warrior
  ifelse [xcor] of one-of warriors < [xcor] of one-of badguys [badguy-left-walk][badguy-right-walk]
end
@#$#@#$#@
GRAPHICS-WINDOW
11
10
864
448
-1
-1
13.0
1
24
1
1
1
0
0
0
1
-32
32
-16
16
0
0
1
ticks
30.0

BUTTON
1007
43
1071
76
Reset
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1017
223
1080
256
->
right-walk
NIL
1
T
OBSERVER
NIL
6
NIL
NIL
1

BUTTON
954
223
1017
256
<-
left-walk
NIL
1
T
OBSERVER
NIL
4
NIL
NIL
1

BUTTON
1197
115
1261
148
Fight!
fight
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
954
314
1019
347
Punch
warrior-punch
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
1018
314
1081
347
Kick
warrior-kick
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
985
191
1048
224
^
warrior-stand
NIL
1
T
OBSERVER
NIL
8
NIL
NIL
1

BUTTON
986
255
1049
288
v
warrior-crouch
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

badguy
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 195 90 240 195 210 210 165 105
Polygon -2674135 true false 105 90 60 195 90 210 135 105
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 210 285 195 300 165 300 150 225 135 300 105 300 90 285 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208

badguy-block
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 90 105 195 60 210 90 105 135
Polygon -2674135 true false 210 105 105 60 90 90 195 135
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 210 285 195 300 165 300 150 225 135 300 105 300 90 285 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208

badguy-jump-kick
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 195 90 240 195 210 210 165 105
Polygon -2674135 true false 150 90 135 195 90 180 105 90
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 180 210 165 225 150 225 150 225 150 225 135 225 120 210 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208
Polygon -2674135 true false 180 210 180 240 75 225 60 165 0 90 28 54 90 120 120 195
Polygon -2674135 true false 165 210 180 240 240 300 180 300 135 255 120 225
Line -16777216 false 180 240 120 210
Line -16777216 false 95 136 118 190
Line -16777216 false 126 122 121 164

badguy-kick1
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 195 90 240 195 210 210 165 105
Polygon -2674135 true false 120 90 165 195 135 210 90 105
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 180 210 165 225 150 225 150 225 150 225 135 225 120 210 120 195 105 90
Polygon -16777216 true false 180 90 195 90 150 150 135 120
Line -6459832 false 191 105 161 105
Line -16777216 false 268 140 239 132
Line -6459832 false 163 143 141 134
Line -16777216 false 232 134 209 113
Line -16777216 false 274 145 251 131
Rectangle -16777216 true false 225 223 225 225
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208
Polygon -2674135 true false 180 210 180 240 135 255 90 240 60 300 30 255 75 195 120 210
Polygon -2674135 true false 180 240 210 270 270 285 210 300 150 285 135 255
Line -16777216 false 225 255 225 255
Rectangle -16777216 true false 120 195 180 195
Rectangle -16777216 true false 120 195 180 210

badguy-kick2
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 195 90 240 195 210 210 165 105
Polygon -2674135 true false 195 150 90 135 105 90 195 105
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 180 210 165 225 150 225 150 225 150 225 135 225 120 210 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208
Polygon -2674135 true false 180 210 180 240 135 255 75 225 0 210 0 165 75 180 120 210
Polygon -2674135 true false 180 240 195 270 240 300 180 300 150 285 135 255
Line -16777216 false 180 240 120 210

badguy-knockout
false
0
Rectangle -7500403 true true 128 274 173 289
Polygon -2674135 true false 180 180 225 285 195 300 150 195
Polygon -2674135 true false -15 285 90 330 105 300 0 255
Circle -7500403 true true 35 215 80
Polygon -2674135 true false 120 225 225 240 240 240 255 255 255 270 255 270 255 270 255 285 240 300 225 300 120 315
Polygon -16777216 true false 240 225 255 225 180 330 180 300
Line -1184463 false 131 105 101 105
Line -1184463 false 118 125 89 117
Line -1184463 false 118 143 96 134
Line -1184463 false 97 179 74 158
Line -1184463 false 109 160 86 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 103 199 118 211 123 234 120 248 77 229 33 222 36 212 53 197 80 195
Polygon -16777216 true false 222 285 165 210 158 217 212 285
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208
Polygon -2674135 true false 180 210 180 225 180 240 135 270 120 300 90 300 90 255 120 210
Polygon -2674135 true false 165 195 285 255 315 255 300 285 225 270 180 240
Line -16777216 false 180 240 135 270

badguy-punch
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 195 90 240 195 210 210 165 105
Polygon -2674135 true false 15 90 120 135 135 105 30 60
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 180 210 165 225 150 225 150 225 150 225 135 225 120 210 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208
Polygon -2674135 true false 180 210 180 225 180 240 135 270 120 300 90 300 90 255 120 210
Polygon -2674135 true false 120 210 240 270 270 270 255 300 180 285 135 255
Line -16777216 false 180 240 135 270

badguy-punch-block
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 135 60 90 105 60 90 105 30
Polygon -2674135 true false 60 135 165 90 180 120 75 165
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 210 285 195 300 165 300 150 225 135 300 105 300 90 285 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208

badguy-victory
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 105 120 60 15 90 0 135 105
Polygon -2674135 true false 195 120 240 15 210 0 165 105
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 210 285 195 300 165 300 150 225 135 300 105 300 90 285 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 30 105 30 105 23 112 30 105
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208

badguy-walk1
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 195 90 240 195 210 210 165 105
Polygon -2674135 true false 105 90 60 195 90 210 135 105
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 195 90 180 195 180 210 165 225 150 225 150 225 150 225 135 225 120 210 120 195 105 90
Polygon -16777216 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208
Polygon -2674135 true false 180 210 180 225 180 240 135 270 120 300 90 300 90 255 120 210
Polygon -2674135 true false 120 210 240 270 270 270 255 300 180 285 135 255
Line -16777216 false 180 240 135 270

badguy-walk2
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -2674135 true false 90 195 184 108 165 90 60 165
Polygon -2674135 true false 195 195 120 105 150 90 225 180
Circle -7500403 true true 110 5 80
Polygon -2674135 true false 194 90 179 195 179 210 164 225 149 225 149 225 149 225 134 225 119 210 119 195 104 90
Polygon -16777216 true false 242 132 257 132 250 132 242 136
Line -16777216 false 187 117 118 170
Line -16777216 false 182 184 188 131
Line -16777216 false 238 233 216 224
Line -16777216 false 255 120 254 128
Line -16777216 false 155 92 111 129
Rectangle -16777216 true false 120 193 180 201
Polygon -2674135 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 117 90 60 15 53 22 107 90
Rectangle -16777216 true false 172 187 186 208
Rectangle -16777216 true false 109 187 123 208
Polygon -2674135 true false 180 210 180 210 180 255 180 255 225 285 180 300 135 270 120 210
Polygon -2674135 true false 180 210 135 255 105 300 75 285 90 240 120 210
Line -16777216 false 121 209 132 260

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

warrior
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 213 180 225 180 225 180 223 180
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

warrior-block
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 210 105 105 60 90 90 195 135
Polygon -10899396 true false 90 105 195 60 210 90 105 135
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

warrior-crouch
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 195 225 210 105 180 90 165 225
Polygon -10899396 true false 120 90 120 225 90 225 90 105
Circle -7500403 true true 110 20 80
Polygon -10899396 true false 105 90 120 165 120 165 120 165 120 165 180 165 180 165 180 165 180 150 180 165 195 90
Polygon -6459832 true false 120 90 105 90 150 165 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 119 165 180 181
Polygon -6459832 true false 122 19 107 31 102 54 105 68 148 49 192 42 189 32 172 17 145 15
Polygon -16777216 true false 213 180 225 180 225 180 223 180
Rectangle -6459832 true false 105 157 128 180
Rectangle -6459832 true false 177 157 195 180
Polygon -10899396 true false 120 180 60 135 30 225 60 240 75 180 150 225 240 195 285 225 300 180 240 165 180 180
Line -16777216 false 30 60 45 105
Line -16777216 false 120 120 120 150
Line -16777216 false 120 180 120 210
Line -16777216 false 90 150 90 195
Line -16777216 false 175 98 170 150
Line -16777216 false 166 183 164 217
Line -16777216 false 203 166 199 206

warrior-flying-punch
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 225 165 285 105 255 75 195 135
Polygon -10899396 true false 225 105 195 90 180 120 210 150
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 210 135 225 150 225 150 225 150 225 165 225 180 210 180 195 195 90
Polygon -6459832 true false 120 90 105 90 150 165 165 150
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -1184463 false 30 240 61 218
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -16777216 true false 15 232 15 225
Polygon -10899396 true false 180 210 180 225 180 240 135 270 120 300 75 300 90 255 120 210
Polygon -10899396 true false 165 210 255 195 240 285 180 285 210 240 181 242
Line -16777216 false 120 210 120 210
Line -16777216 false 55 269 54 269
Line -1184463 false 63 237 45 270
Rectangle -16777216 true false 15 90 14 91
Rectangle -16777216 true false 65 115 66 115
Polygon -16777216 true false 48 87 48 86 47 86
Polygon -10899396 true false 106 91 52 116 33 172 68 190 84 135 113 124

warrior-flying-punch2
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 255 120 270 30 240 15 210 120
Polygon -10899396 true false 225 75 195 90 180 135 240 120
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 210 135 225 150 225 150 225 150 225 165 225 180 210 180 195 195 90
Polygon -6459832 true false 120 90 105 90 150 165 165 150
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -1184463 false 30 240 61 218
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -1184463 true false 18 270 30 255 15 270 28 270
Rectangle -6459832 true false 114 187 128 208
Rectangle -16777216 true false 15 232 15 225
Polygon -10899396 true false 180 210 180 225 180 240 135 270 120 300 75 300 90 255 120 210
Polygon -10899396 true false 165 210 255 195 240 285 180 285 210 240 181 242
Line -16777216 false 120 210 120 210
Line -16777216 false 55 269 54 269
Line -1184463 false 63 237 45 270
Rectangle -16777216 true false 15 90 14 91
Rectangle -16777216 true false 65 115 66 115
Polygon -16777216 true false 48 87 48 86 47 86
Polygon -10899396 true false 106 91 52 116 33 172 68 190 84 135 113 124

warrior-jump-kick1
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 165 120 270 165 285 135 180 90
Polygon -10899396 true false 135 120 30 165 15 135 120 90
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 225 120 225 120 225 180 225 180 225 180 225 180 225 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 213 180 225 180 225 180 223 180
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208
Polygon -10899396 true false 120 225 60 180 30 270 60 285 75 225 150 270 225 240 255 270 300 240 225 195 180 225

warrior-jump-kick2
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 210 15 165 120 195 135 240 30
Polygon -10899396 true false 135 120 30 165 15 135 120 90
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 225 120 225 120 225 180 225 180 225 180 225 180 225 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 213 180 225 180 225 180 223 180
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208
Polygon -10899396 true false 120 225 90 225 75 240 90 270 150 270 150 270 240 240 300 255 300 210 225 210 180 225
Line -16777216 false 135 240 165 240
Line -16777216 false 165 240 180 255

warrior-kick1
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 180 210 225 105 195 90 150 195
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 210 135 225 150 225 150 225 150 225 165 225 180 210 180 195 195 90
Polygon -6459832 true false 120 90 105 90 150 165 165 150
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -16777216 false 60 225 61 218
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -16777216 true false 45 232 56 240
Polygon -10899396 true false 180 210 180 225 180 240 135 270 120 300 75 300 90 255 120 210
Polygon -10899396 true false 150 195 225 180 270 270 240 300 210 240 165 240
Line -16777216 false 120 210 120 210
Line -16777216 false 195 90 150 195
Line -16777216 false 189 189 150 195

warrior-kick2
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 163 101 58 56 43 86 148 131
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 210 135 225 150 225 150 225 150 225 165 225 180 210 180 195 195 90
Polygon -6459832 true false 147 138 133 135 180 195 180 165
Line -16777216 false 74 235 74 235
Line -16777216 false 79 232 77 233
Line -16777216 false 139 138 169 113
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208
Polygon -10899396 true false 180 210 180 225 180 240 135 270 120 300 75 300 90 255 120 210
Polygon -10899396 true false 165 195 240 150 315 120 315 165 240 195 180 240
Line -16777216 false 120 210 120 210
Line -16777216 false 165 105 128 87
Line -16777216 false 136 135 91 105

warrior-knockout
false
0
Rectangle -7500403 true true 67 259 112 274
Polygon -10899396 true false 75 285 180 330 195 300 90 255
Polygon -10899396 true false 75 225 180 180 195 210 90 255
Circle -7500403 true true 35 215 80
Polygon -10899396 true false 90 300 195 285 285 315 300 300 300 270 225 255 300 240 300 210 285 195 195 225 90 210
Polygon -6459832 true false 90 285 90 300 195 225 165 225
Line -1184463 false 109 105 139 105
Line -1184463 false 122 125 151 117
Line -1184463 false 92 173 114 164
Line -1184463 false 158 179 181 158
Line -1184463 false 146 160 169 146
Rectangle -6459832 true false 103 240 111 300
Polygon -6459832 true false 32 199 17 211 12 234 15 248 58 229 102 222 99 212 82 197 55 195
Polygon -16777216 true false 63 150 120 75 127 82 73 150
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

warrior-punch
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 270 45 165 90 180 120 285 75
Polygon -10899396 true false 105 210 150 105 120 90 75 195
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 210 135 225 150 225 150 225 150 225 165 225 180 210 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208
Polygon -10899396 true false 120 210 120 225 120 240 165 270 180 300 210 300 210 255 180 210
Polygon -10899396 true false 180 210 60 270 30 270 45 300 120 285 165 255
Line -16777216 false 120 240 165 270

warrior-punch-block
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 210 135 105 90 90 120 195 165
Polygon -10899396 true false 195 105 150 30 180 15 225 90
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

warrior-spin-kick-left
false
0
Rectangle -7500403 true true 128 79 173 94
Polygon -10899396 true false 90 15 135 120 105 135 60 30
Polygon -10899396 true false 165 120 270 165 285 135 180 90
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 195 90 180 195 180 225 180 225 180 225 120 225 120 225 120 225 120 225 120 195 105 90
Polygon -6459832 true false 180 90 195 90 120 195 120 165
Line -6459832 false 191 105 161 105
Line -6459832 false 178 125 149 117
Line -6459832 false 163 143 141 134
Line -6459832 false 142 179 119 158
Line -6459832 false 154 160 131 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 178 4 193 16 198 39 195 53 152 34 108 27 111 17 128 2 155 0
Polygon -16777216 true false 87 180 75 180 75 180 77 180
Rectangle -6459832 true false 172 187 186 208
Rectangle -6459832 true false 109 187 123 208
Polygon -10899396 true false 135 210 180 225 165 270 180 300 135 300 120 270 120 240 60 210 0 210 0 165 60 165
Line -1184463 false 255 195 225 195
Line -1184463 false 240 210 255 225

warrior-spin-kick-right
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 210 15 165 120 195 135 240 30
Polygon -10899396 true false 135 120 30 165 15 135 120 90
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 225 120 225 120 225 180 225 180 225 180 225 180 225 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 213 180 225 180 225 180 223 180
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208
Polygon -10899396 true false 165 210 120 225 135 270 120 300 165 300 180 270 180 240 240 210 300 210 300 165 240 165
Line -1184463 false 45 195 75 195
Line -1184463 false 60 210 45 225

warrior-victory
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 195 120 240 15 210 0 165 105
Polygon -10899396 true false 105 120 60 15 90 0 135 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 213 180 225 180 225 180 223 180
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

warrior-walk1
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 120 210 135 225 150 225 150 225 150 225 165 225 180 210 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208
Polygon -10899396 true false 120 210 120 225 120 240 165 270 180 300 210 300 210 255 180 210
Polygon -10899396 true false 180 210 60 270 30 270 45 300 120 285 165 255
Line -16777216 false 120 240 165 270

warrior-walk2
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 210 195 116 108 135 90 240 165
Polygon -10899396 true false 105 195 180 105 150 90 75 180
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 106 90 121 195 121 210 136 225 151 225 151 225 151 225 166 225 181 210 181 195 196 90
Polygon -16777216 true false 58 132 43 132 50 132 58 136
Line -16777216 false 113 117 182 170
Line -16777216 false 118 184 112 131
Line -16777216 false 62 233 84 224
Line -16777216 false 45 120 46 128
Line -16777216 false 145 92 189 129
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208
Polygon -10899396 true false 120 210 120 210 120 255 120 255 75 285 120 300 165 270 180 210
Polygon -10899396 true false 120 210 165 255 195 300 225 285 210 240 180 210
Line -16777216 false 179 209 168 260

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0-beta1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
