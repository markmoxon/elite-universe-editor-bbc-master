\ ******************************************************************************
\
\ ELITE UNIVERSE EDITOR (PART 2)
\
\ The Universe Editor is an extended version of BBC Micro Elite by Mark Moxon
\
\ The original 6502 Second Processor Elite was written by Ian Bell and David
\ Braben and is copyright Acornsoft 1985
\
\ The original BBC Master Elite was written by Ian Bell and David Braben and is
\ copyright Acornsoft 1986
\
\ The extra code in the Universe Editor is copyright Mark Moxon
\
\ The code on this site is identical to the source discs released on Ian Bell's
\ personal website at http://www.elitehomepage.org/ (it's just been reformatted
\ to be more readable)
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ******************************************************************************

\ ******************************************************************************
\
\       Name: UniverseEditor
\       Type: Subroutine
\   Category: Universe editor
\    Summary: The entry point for the universe editor
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   edit3               Rejoin the main loop after the key has been processed
\
\ ******************************************************************************

.UniverseEditor

 JSR ApplyMods          \ Apply the mods required for the Universe Editor

 LDA #0                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 0 (space
                        \ view)

 JSR SIGHT              \ Draw the laser crosshairs

 JSR RESET              \ Call RESET to initialise most of the game variables

 LDA #0                 \ Send a #SETVDU19 0 command to the I/O processor to
 JSR DOVDU19            \ switch to the mode 1 palette for the space view,
                        \ which is yellow (colour 1), red (colour 2) and cyan
                        \ (colour 3)

 JSR SOLAR              \ Add the sun, planet and stardust, according to the
                        \ current system seeds

 LDX #1                 \ Get the details for the sun from slot 1
 STX currentSlot        \
 STX MCNT               \ Also, set MCNT to 1 so we don't update the compass in
 JSR GetShipData        \ the DIALS routine

 JSR ZINF               \ Initialise the sun so it's in front of us
 JSR InitialiseShip

 LDA #%10000001         \ Set x_sign = -1, so the sun is to the left
 STA INWK+2

 JSR STORE              \ Store the updated sun

 JSR LL9                \ Draw the sun

 LDX #0                 \ Get the details for the planet from slot 0
 STX currentSlot
 JSR GetShipData

 LDA #128               \ Set the planet to a meridian planet
 STA FRIN
 STA TYPE

 JSR ZINF               \ Initialise the planet so it's in front of us
 JSR InitialiseShip

 LDA #%00000001         \ Set x_sign = 1, so the planet is to the right
 STA INWK+2

 JSR STORE              \ Store the updated planet

 JSR LL9                \ Draw the planet

 LDX #0                 \ Set the current slot to 0 (planet)
 STX currentSlot

 JSR PrintSlotNumber    \ Print the current slot number at text location (0, 1)

 JSR UpdateDashboard    \ Update the dashboard to show the planet's values

.edit1

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 BNE edit1              \ If a key was already being held down when we entered
                        \ this routine, keep looping back up to edit1, until
                        \ the key is released

.edit2

 LDY #2                 \ Delay for 2 vertical syncs (2/50 = 0.04 seconds) to
 JSR DELAY              \ make the rate of key repeat manageable

 JSR RDKEY              \ Scan the keyboard, returning the internal key number
                        \ in X (or 0 for no key press)

 BEQ edit2              \ Keep looping up to edit2 until a key is pressed

 JSR ProcessKey         \ Process the key press

.edit3

 LDX currentSlot        \ Get the ship data for the current ship, so we know the
 JSR GetShipData        \ current ship data is always in INWK for the main loop

 JSR UpdateDashboard    \ Update the dashboard

 LDA repeatingKey       \ Fetch the type of key press (0 = non-repeatable,
                        \ 1 = repeatable)

 BNE edit2              \ Loop back to wait for next key press (for repeatable
                        \ keys)

 BEQ edit1              \ Loop back to wait for next key press (non-repeatable
                        \ keys)

\ ******************************************************************************
\
\       Name: keyTable
\       Type: Variable
\   Category: Universe editor
\    Summary: Movement key table for each of the four views
\
\ ******************************************************************************

.keyTable

                        \ x-plus        x-minus
                        \ z-plus        z-minus
                        \ xrot-plus     xrot-minus
                        \ zrot-plus     zrot-minus

IF _6502SP_VERSION

                        \ Front view

 EQUB &79, &19          \ Right arrow   Left arrow
 EQUB &62, &68          \ SPACE         ?
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

                        \ Rear view

 EQUB &19, &79          \ Left arrow    Right arrow
 EQUB &68, &62          \ ?             SPACE
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

                        \ Left view

 EQUB &68, &62          \ ?             SPACE
 EQUB &79, &19          \ Right arrow   Left arrow
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

                        \ Right view

 EQUB &62, &68          \ SPACE         ?
 EQUB &19, &79          \ Left arrow    Right arrow
 EQUB &51, &42          \ S             X
 EQUB &67, &66          \ >             <

ELIF _MASTER_VERSION

                        \ Front view

 EQUB &8D, &8C          \ Right arrow   Left arrow
 EQUB &20, &2F          \ SPACE         ?
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

                        \ Rear view

 EQUB &8C, &8D          \ Left arrow    Right arrow
 EQUB &2F, &20          \ ?             SPACE
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

                        \ Left view

 EQUB &2F, &20          \ ?             SPACE
 EQUB &8D, &8C          \ Right arrow   Left arrow
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

                        \ Right view

 EQUB &20, &2F          \ SPACE         ?
 EQUB &8C, &8D          \ Left arrow    Right arrow
 EQUB &53, &58          \ S             X
 EQUB &2E, &2C          \ >             <

ENDIF

\ ******************************************************************************
\
\       Name: CheckShiftCtrl
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Check for SHIFT and CTRL
\
\ ******************************************************************************

.CheckShiftCtrl

 STZ shiftCtrl          \ We now test for SHIFT and CTRL and set bit 7 and 6 of
                        \ shiftCtrl accordingly, so zero the byte first

IF _6502SP_VERSION

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

ELIF _MASTER_VERSION

IF _SNG47

 JSR CTRL               \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

ELIF _COMPACT

 JSR CTRLmc             \ Scan the keyboard to see if CTRL is currently pressed,
                        \ returning a negative value in A if it is

ENDIF

ENDIF

 BPL P%+5               \ If CTRL is being pressed, set bit 7 of shiftCtrl
 SEC                    \ (which we will shift into bit 6 below)
 ROR shiftCtrl

IF _6502SP_VERSION

 LDX #0                 \ Call DKS4 with X = 0 to check whether the SHIFT key is
 JSR DKS4               \ being pressed

ELIF _MASTER_VERSION

IF _SNG47

 LDA #0                 \ Call DKS4 to check whether the SHIFT key is being
 JSR DKS4               \ pressed

ELIF _COMPACT

 LDA #0                 \ Call DKS4mc to check whether the SHIFT key is being
 JSR DKS4mc             \ pressed

ENDIF

ENDIF

 CLC                    \ If SHIFT is being pressed, set the C flag, otherwise
 BPL P%+3               \ clear it
 SEC

 ROR shiftCtrl          \ Shift the C flag into bit 7 of shiftCtrl, moving the
                        \ CTRL bit into bit 6, so we now have SHIFT and CTRL
                        \ captured in bits 7 and 6 of shiftCtrl

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ProcessKey
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Process key presses
\
\ ******************************************************************************

.ProcessKey

 PHA                    \ Store the key press on the stack

 JSR CheckShiftCtrl     \ Check for SHIFT and CTRL and set shiftCtrl accordingly

 LDX #1                 \ Set repeatingKey = 1 to indicate that the following
 STX repeatingKey       \ keys are repeating keys

 LDA VIEW               \ Set Y = VIEW * 8, to act as an index into keyTable
 ASL A
 ASL A
 ASL A
 TAY

 PLA                    \ Retrieve the key press from the stack

 LDX #0                 \ Set X = 0 for the x-axis

 CMP keyTable,Y         \ Right arrow (move ship right along the x-axis)
 BNE keys1
 LDY #0
 JMP MoveShip

.keys1

 CMP keyTable+1,Y       \ Left arrow (move ship left along the x-axis)
 BNE keys2
 LDY #%10000000
 JMP MoveShip

.keys2

 LDX #3                 \ Set X = 3 for the y-axis

 CMP #keyUp             \ Up arrow (move ship up along the y-axis)
 BNE keys3
 LDY #0
 JMP MoveShip

.keys3

 CMP #keyDown           \ Down arrow (move ship down along the y-axis)
 BNE keys4
 LDY #%10000000
 JMP MoveShip

.keys4

 LDX #6                 \ Set X = 6 for the z-axis

 CMP keyTable+2,Y       \ SPACE (move ship away along the z-axis)
 BNE keys5
 LDY #0
 JMP MoveShip

.keys5

 CMP keyTable+3,Y       \ ? (move ship closer along the z-axis)
 BNE keys6
 LDY #%10000000
 JMP MoveShip

.keys6

 CMP #keyK              \ K (rotate ship around the y-axis)
 BNE keys7

 LDX #0                 \ Rotate (sidev, nosev) by a small positive angle (yaw)
 STX RAT2
 LDX #21
 LDY #9
 JMP RotateShip

.keys7

 CMP #keyL              \ L (rotate ship around the y-axis)
 BNE keys8

 LDX #%10000000         \ Rotate (sidev, nosev) by a small negative angle (yaw)
 STX RAT2
 LDX #21
 LDY #9
 JMP RotateShip

.keys8

 CMP keyTable+4,Y       \ S (rotate ship around the x-axis)
 BNE keys9

 LDX #0                 \ Rotate (roofv, nosev) by a small positive angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #9
 JMP RotateShip

.keys9

 CMP keyTable+5,Y       \ X (rotate ship around the x-axis)
 BNE keys10

 LDX #%10000000         \ Rotate (roofv, nosev) by a small negative angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #9
 JMP RotateShip

.keys10

 CMP keyTable+6,Y       \ > (rotate ship around the x-axis)
 BNE keys11

 LDX #0                 \ Rotate (roofv, sidev) by a small positive angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #21
 JMP RotateShip

.keys11

 CMP keyTable+7,Y       \ < (rotate ship around the x-axis)
 BNE keys12

 LDX #%10000000         \ Rotate (roofv, sidev) by a small negative angle
 STX RAT2               \ (pitch)
 LDX #15
 LDY #21
 JMP RotateShip

.keys12

 CMP #key7              \ 7 (update the ship's speed in INWK+27, in the range
 BNE keys13             \ 0 to 40)
 LDX #27
 LDA #255
 LDY #41
 JMP ChangeValue

.keys13

 CMP #key1              \ 1 (update the ship's acceleration in INWK+28, in the
 BNE keys14             \ range -128 to 127)
 LDX #28
 LDA #127
 LDY #128
 JMP ChangeValue

.keys14

 CMP #key8              \ 8 (update the ship's roll counter in INWK+29)
 BNE keys15
 LDX #29
 JMP ChangeCounter

.keys15

 CMP #key9              \ 9 (update the ship's pitch counter in INWK+30)
 BNE keys16
 LDX #30
 JMP ChangeCounter

.keys16

 CMP #key0              \ 0 (update the ship's energy in INWK+35, in the range
 BNE keys17             \ 0 to 255)
 LDX #35
 LDA #255
 LDY #0
 JMP ChangeValue

.keys17

 CMP #key6              \ 6 (update the ship's aggression level in INWK+32)
 BNE keys18
 JMP ChangeAggression

.keys18

 LDX #0                 \ Set repeatingKey = 0 to indicate that the following
 STX repeatingKey       \ keys are non-repeating keys

 CMP #key2              \ 2 (toggle the ship's AI in bit 7 of INWK+32)
 BNE keys19
 LDX #32
 LDA #%10000000
 JMP ToggleValue

.keys19

 CMP #key3              \ 3 (toggle the ship's Innocent Bystander status in
 BNE keys20             \ bit 5 of INWK+36, NEWB)
 LDX #36
 LDA #%00100000
 JMP ToggleValue

.keys20

 CMP #key4              \ 4 (toggle the ship's Cop status in bit 6 of INWK+36,
 BNE keys21             \ NEWB)
 LDX #36
 LDA #%01000000
 JMP ToggleValue

.keys21

 CMP #key5              \ 5 (toggle the ship's Hostile status in bit 6 of
 BNE keys22             \ INWK+32)
 LDX #32
 LDA #%01000000
 JMP ToggleValue

.keys22

 CMP #keyM              \ M (update the number of missiles in bits 0-2 of 
 BNE keys23             \ INWK+31)
 JMP ChangeMissiles

.keys23

 CMP #keyT              \ T (toggle the trader/bounty hunter/pirate flag in
 BNE keys24             \ bits 0, 1, 3 of INWK+36, NEWB)
 JMP ToggleShipType

.keys24

 CMP #keyC              \ 4 (toggle the ship's Cop status in bit 6 of INWK+36,
 BNE keys25             \ NEWB)
 LDX #36
 LDA #%00010000
 JMP ToggleValue

.keys25

 CMP #keyE              \ E (toggle the ship's E.C.M. status in bit 0 of
 BNE keys26             \ INWK+32)
 LDX #32
 LDA #%00000001
 JMP ToggleValue

.keys26

 CMP #f0                \ f0 (front view)
 BEQ keys27

 CMP #f1                \ f1 (rear view)
 BEQ keys27

 CMP #f2                \ f2 (left view)
 BEQ keys27

 CMP #f3                \ f3 (right view)
 BNE keys28

.keys27

 JMP ChangeView         \ Process a change of view

.keys28

 CMP #keyO              \ O (toggle station/sun)
 BNE P%+5
 JMP SwapStationSun

 CMP #keyP              \ P (toggle planet type)
 BNE P%+5
 JMP TogglePlanetType

 CMP #keyReturn         \ RETURN (add ship)
 BNE P%+5
 JMP AddShip

 CMP #keyW              \ W (next slot)
 BNE P%+5
 JMP NextSlot

 CMP #keyQ              \ Q (previous slot)
 BNE P%+5
 JMP PreviousSlot

 CMP #keyR              \ R (reset current ship)
 BNE P%+5
 JMP ResetShip

 CMP #keyH              \ H (highlight on scanner)
 BNE P%+5
 JMP HighlightScanner

 CMP #keyN              \ N (target missile)
 BNE P%+5
 JMP TargetMissile

 CMP #keyAt             \ @ (show disc access menu)
 BNE P%+5
 JMP ShowDiscMenu

 CMP #keyEscape         \ ESCAPE (jump to QuitEditor to quit the Universe
 BNE P%+5               \ Editor)
 JMP QuitEditor

                        \ The following controls only apply to ships in slots 2
                        \ and up, and do not apply to the planet, sun or station

 LDX currentSlot        \ Get the current slot number to pass to the following
                        \ routines, so they can do nothing (and give an error
                        \ beep) if this is the station or planet

 CMP #keyDelete         \ DELETE (delete ship)
 BNE P%+5
 JMP DeleteShip

 CMP #keyCopy           \ COPY (copy ship)
 BNE P%+5
 JMP CopyShip

 CMP #keyA              \ A (fire laser)
 BNE P%+5
 JMP FireLaser

 CMP #keyD              \ E (explode ship)
 BNE P%+5
 JMP ExplodeShip

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DrawShips
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Draw all ships, planets, stations etc.
\
\ ******************************************************************************

.DrawShips

 LDX #0                 \ We count through all the occupied ship slots, from
                        \ slot 0 and up

.draw1

 LDA FRIN,X             \ If the slot is empty, return from the subroutine as
 BEQ draw4              \ we are done

 PHX                    \ Store the counter on the stack

 JSR GetShipData        \ Fetch the details for the ship in slot X

 LDA INWK+31            \ If bit 5 of byte #31 is clear, then the ship is not
 AND #%00100000         \ exploding, so jump to draw2 to skip the following
 BEQ draw2

                        \ The ship is exploding

\ LDA #&A5               \ Re-enable DOEXP
\ STA DOEXP+9

 JSR DrawShip+3         \ Draw the ship (but not on the scanner)

\ LDA #&60               \ Disable DOEXP again
\ STA DOEXP+9

 BNE draw3

.draw2

 JSR DrawShip           \ Draw the ship

.draw3

 PLX                    \ Retrieve the counter from the stack

 INX                    \ Move to the next slot

 CPX #NOSH              \ Loop back until we have drawn all the ships
 BCC draw1

.draw4

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DrawShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Draw a single ship
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   DrawShip+3          Do not draw the ship on the scanner
\
\ ******************************************************************************

.DrawShip

 JSR MV5                \ Draw the ship on the scanner

 JSR PLUT               \ Call PLUT to update the geometric axes in INWK to
                        \ match the view (front, rear, left, right)

 JSR LL9                \ Draw the ship

 LDY #31                \ Fetch the ship's explosion/killed state from byte #31
 LDA INWK+31            \ and copy it to byte #31 in INF (so the ship's data in
 STA (INF),Y            \ K% gets updated)

 LDX currentSlot        \ Get the ship data for the current slot, as otherwise
 JMP GetShipData        \ we will leave the wrong axes in INWK, and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: EraseShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Erase the current ship from the screen
\
\ ******************************************************************************

.EraseShip

 LDA INWK+31            \ If bit 5 of byte #31 is clear, then the ship is not
 AND #%00100000         \ exploding, so jump to eras2
 BEQ eras2

 LDA INWK+31            \ If bit 3 of byte #31 is clear, then the explosion is
 AND #%00001000         \ not already being shown on-screen, so jump to eras2
 BEQ eras1              \ to return from the subroutine

 JSR LL14               \ Call LL14 to draw the existing cloud to remove it

.eras1

 RTS                    \ Return from the subroutine

.eras2

 JSR MV5                \ Draw the current ship on the scanner to remove it

 LDX TYPE               \ Get the current ship type

 LDA shpcol,X           \ Set A to the ship colour for this type, from the X-th
                        \ entry in the shpcol table

IF _6502SP_VERSION

 JSR DOCOL              \ Send a #SETCOL command to the I/O processor to switch
                        \ to this colour

ELIF _MASTER_VERSION

 STA COL                \ Switch to this colour

ENDIF

 LDA NEWB               \ Set bit 7 of the ship to indicate it has docked (so
 ORA #%10000000         \ the call to LL9 removes it from the screen)
 STA NEWB

 JMP LL9                \ Draw the existing ship to erase it and mark it as gone
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: SwapStationSun
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Toggle through the sun and two types of station
\
\ ******************************************************************************

.SwapStationSun

 LDX #1                 \ Switch to slot 1, which is the station or sun, and
 JSR SwitchToSlot       \ highlight the existing contents

 LDA TYPE               \ If we are showing the sun, jump to swap1 to switch it
 BMI swap1              \ to a Coriolis space station

 LDA tek                \ If we are showing a Coriolis station (i.e. tech level
 CMP #10                \ < 10), jump to swap2 to switch it to a Dodo station
 BCC swap2

                        \ Otherwise we are showing a Dodo station, so switch it
                        \ to the sun

 JSR EraseShip          \ Erase the existing space station

 JSR KS4                \ Switch to the sun, showing the space station bulb

 JSR SPBLB              \ Call SPBLB to redraw the space station bulb, which
                        \ will erase it from the dashboard

 JSR SetSBulb           \ Show or hide the space station bulb according to the
                        \ setting of bit 4 of INWK+36 (NEWB)

 JSR ZINF               \ Reset the sun's data block

 LDA #129               \ Set the type for the sun
 STA TYPE

 JSR InitialiseShip     \ Initialise the sun so it's in front of us

 JSR STORE              \ Store the updated sun

 BNE swap4              \ Jump to swap3 (this BNE is effectively a JMP as A is
                        \ never zero)

.swap1

                        \ Remove sun and show Coriolis

 JSR WPLS               \ Call WPLS to remove the sun from the screen, as we
                        \ can't have both the sun and the space station at the
                        \ same time

 LDA #SST               \ Set the ship type to the space station
 STA TYPE

 JSR ZINF               \ Reset the station coordinates

 LDA #1                 \ Set the tech level for a Coriolis station
 STA tek

 BNE swap3              \ Jump to swap3 (this BNE is effectively a JMP as A is
                        \ never zero)

.swap2

                        \ Switch from Coriolis to Dodo

 JSR EraseShip          \ Erase the existing space station

 LDA #10                \ Set the tech level for a Dodo station
 STA tek

.swap3

 JSR NWSPS+3            \ Add a new space station to our local bubble of
                        \ universe, skipping the drawing of the space station
                        \ bulb

 JSR SetSBulb           \ Show or hide the space station bulb according to the
                        \ setting of bit 4 of INWK+36 (NEWB)

 JSR InitialiseShip     \ Initialise the station so it's in front of us

 JSR STORE              \ Store the updated station

.swap4

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: RotateShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Rotate ship in space
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The first vector to rotate:
\
\                         * If X = 15, rotate roofv_x
\                                      then roofv_y
\                                      then roofv_z
\
\                         * If X = 21, rotate sidev_x
\                                      then sidev_y
\                                      then sidev_z
\
\   Y                   The second vector to rotate:
\
\                         * If Y = 9,  rotate nosev_x
\                                      then nosev_y
\                                      then nosev_z
\
\                         * If Y = 21, rotate sidev_x
\                                      then sidev_y
\                                      then sidev_z
\
\   RAT2                The direction of the pitch or roll to perform, positive
\                       or negative (i.e. the sign of the roll or pitch counter
\                       in bit 7)
\
\ ******************************************************************************

.RotateShip

 PHX                    \ Store X and Y on the stack
 PHY

 JSR MV5                \ Draw the ship on the scanner to remove it

 PLY                    \ Store X and Y on the stack
 PLX
 PHX
 PHY

 JSR MVS5               \ Rotate vector_x by a small angle

 PLA                    \ Retrieve X and Y from the stack and add 2 to each of
 CLC                    \ them to point to the next axis
 ADC #2
 TAY
 PLA
 ADC #2
 TAX

 PHX                    \ Store X and Y on the stack
 PHY

 JSR MVS5               \ Rotate vector_y by a small angle

 PLA                    \ Retrieve X and Y from the stack and add 2 to each of
 CLC                    \ them to point to the next axis
 ADC #2
 TAY
 PLA
 ADC #2
 TAX

 JSR MVS5               \ Rotate vector_z by a small angle

 JSR TIDY               \ Call TIDY to tidy up the orientation vectors, to
                        \ prevent the ship from getting elongated and out of
                        \ shape due to the imprecise nature of trigonometry
                        \ in assembly language

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: MoveShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Move ship in space
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Axis (0, 3, 6 for x, y, z)
\
\   Y                   Direction of movement (bit 7)
\
\ ******************************************************************************

.MoveShip

 STX K                  \ Store the axis in K, so we can retrieve it below

 STY K+3                \ Store the sign of the movement in the sign byte of
                        \ K(3 2 1)

 JSR MV5                \ Draw the ship on the scanner to remove it

 LDX #0                 \ Set the high byte of K(3 2 1) to 0
 STX K+2

 BIT shiftCtrl          \ IF CTRL is being pressed, jump to move2
 BVS move1

 BMI move2              \ IF SHIFT is being pressed, jump to move2

 LDY #1                 \ Set Y = 1 to use as the delta and jump to move3 (this
 BNE move3              \ BNE is effectively a JMP as Y is never zero)

.move1

 LDY #200               \ Set Y = 200 to use as the delta and jump to move3
 BNE move3              \ (this BNE is effectively a JMP as Y is never zero)

.move2

 LDY #20                \ Set Y = 20 to use as the delta

.move3

 LDA TYPE               \ If this is the planet or sun, jump to move4
 BMI move4

 STY K+1                \ Set the low byte of K(3 2 1) to the delta
 BPL move5

.move4

 STY K+2                \ Set the high byte of K(3 2 1) to the delta

.move5

 LDX K                  \ Fetch the axis into X (the comments below are for the
                        \ x-axis)

 JSR MVT3               \ K(3 2 1) = (x_sign x_hi x_lo) + K(3 2 1)

 LDA K+1                \ Set (x_sign x_hi x_lo) = K(3 2 1)
 STA INWK,X
 LDA K+2
 STA INWK+1,X
 LDA K+3
 STA INWK+2,X

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: InitialiseShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Set the coordinates and orientation for a ship just in front of us
\
\ ******************************************************************************

.InitialiseShip

                        \ This routine is called following ZINF, so the
                        \ orientation vectors are set as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0, -1)

 LDA TYPE               \ If this is a ship or station, jump to init3 to set a
 BPL init3              \ distance of 2 or 5

 LDA #%10000000         \ Pitch the planet so the crater is visible (in case we
 JSR TWIST2             \ switch planet types straight away)
 LDA #%10000000
 JSR TWIST2

 LDA #127               \ Set the pitch and roll counters to 127 (no damping
 STA INWK+29            \ so the planet's rotation doesn't slow down)
 STA INWK+30

 LDA #2                 \ This is a planet/sun, so set A = 2 to store as the
                        \ sign-byte distance

 LDX VIEW               \ If this is the left or right view, jump to init1
 CPX #2
 BCC init1

 STA INWK+2             \ This is the front or rear view, so set x_sign = 2

 BCS init2              \ Jump to init2 (this BCC is effectively a JMP as we
                        \ just passed through a BCS)

.init1

 STA INWK+8             \ This is the left or right view, so set z_sign = 2

.init2

 LDA #0                 \ Set A = 0 to store as the high-byte distance for the
                        \ planet/sun

 BEQ init5              \ Jump to init5 (this BEQ is effectively a JMP as A is
                        \ always zero)

.init3

 CMP #SST               \ If this is a space station, jump to init4 to set a
 BEQ init4              \ distance of 5

 LDA INWK+32            \ This is a ship, so enable AI by setting bit 7 of
 ORA #%10000000         \ INWK+32
 STA INWK+32

 LDA #2                 \ Set A = 2 to store as the high-byte distance for the
                        \ new ship, so it's is a little way in front of us

 BNE init5              \ Jump to init5 (this BNE is effectively a JMP as A is
                        \ never zero)

.init4

 LDA #5                 \ Set A = 5 to store as the high-byte distance for the
                        \ new station, so it's a little way in front of us

.init5

                        \ This routine is called following ZINF, so the
                        \ orientation vectors are set as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0, -1)

 LDX VIEW               \ If this is the front view, jump to init11 to set z_hi
 CPX #1
 BCC init11

 BEQ init7              \ If this is the rear view, jump to init7 to set z_sign
                        \ and z_hi and point the ship away from us

 STA INWK+1             \ This is the left or right view, so set the distance
                        \ in x_hi

 CPX #3                 \ If this is the right view, jump to init6
 BEQ init6

                        \ This is the left view, so spawn the ship to the left
                        \ (negative y_sign) and pointing away from us:
                        \
                        \   sidev = (0,   0,  1)
                        \   roofv = (0,   1,  0)
                        \   nosev = (-1,  0,  0)

 LDA INWK+2             \ This is the left view, so negate x_sign
 ORA #%10000000
 STA INWK+2

 LDX #0                 \ Set byte #22 = sidev_x_hi = 0
 STX INWK+22

 STX INWK+14            \ Set byte #14 = nosev_z_hi = 0

 LDX #96                \ Set byte #26 = sidev_z_hi = 96 = 1
 STX INWK+26

 LDX #128+96            \ Set byte #10 = nosev_x_hi = -96 = -1
 STX INWK+10

 LDA TYPE               \ If this is not the station, jump to init10
 CMP #SST
 BNE init10

                        \ This is the station, so flip it around so the slot is
                        \ pointing at us

 LDX #96                \ Set byte #10 = nosev_x_hi = 96 = 1
 STX INWK+10

 BNE init10             \ Jump to init10 (this BNE is effectively a JMP as X is
                        \ never zero)

.init6

                        \ This is the right view, so spawn the ship pointing
                        \ away from us:
                        \
                        \   sidev = (0,  0, -1)
                        \   roofv = (0,  1,  0)
                        \   nosev = (1,  0,  0)

 LDX #0                 \ Set byte #22 = sidev_x_hi = 0
 STX INWK+22

 STX INWK+14            \ Set byte #14 = nosev_z_hi = 0

 LDX #128+96            \ Set byte #26 = sidev_z_hi = -96 = -1
 STX INWK+26

 LDX #96                \ Set byte #10 = nosev_x_hi = 96 = 1
 STX INWK+10

 LDA TYPE               \ If this is not the station, jump to init10
 CMP #SST
 BNE init10

                        \ This is the station, so flip it around so the slot is
                        \ pointing at us

 LDX #128+96            \ Set byte #10 = nosev_x_hi = -96 = -1
 STX INWK+10

 BNE init10             \ Jump to init10 (this BNE is effectively a JMP as X is
                        \ never zero)

.init7

                        \ This is the rear view, so spawn the ship behind us
                        \ (negative z_sign) and pointing away from us

 PHA                    \ Store the distance on the stack

 LDA INWK+8             \ This is the rear view, so negate z_sign
 ORA #%10000000
 STA INWK+8

 LDX #128+96            \ Set byte #14 = nosev_z_hi = -96 = -1
 STX INWK+14

 LDA TYPE               \ If this is not the station, jump to init8
 CMP #SST
 BNE init8

                        \ This is the station, so flip it around so the slot is
                        \ pointing at us

 LDX #96                \ Set byte #14 = nosev_z_hi = 96 = 1
 STX INWK+14

.init8

 PLA                    \ Retrieve the distance from the stack

.init9

 STA INWK+7             \ Store the distance in z_hi

.init10

 RTS                    \ Return from the subroutine

.init11

                        \ This is the front view, so flip the ship around so it
                        \ is pointing at us

 LDX #10                \ Flip the ship around nosev to point it towards us
 JSR FlipShip

 JMP init9              \ Jump to init9

\ ******************************************************************************
\
\       Name: AddShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Add a new ship
\
\ ******************************************************************************

.AddShip

 LDA #8                 \ Print extended text token 8 ("TYPE?") as a prompt
 JSR PrintPrompt

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A (and X)

 PHA                    \ Store the key press on the stack

 LDA #8                 \ Print extended text token 8 ("TYPE?") as a prompt to
 JSR PrintPrompt        \ remove it

 PLA                    \ Retrieve the key press from the stack

 CMP #'1'               \ If key is less than '1' then it is invalid, so jump
 BCC add6               \ to add6 to make an error beep and return from the
                        \ subroutine

.add1

 CMP #'9'+1             \ If key is '1' to '9', jump to add2 to process
 BCC add2

IF _6502SP_VERSION

 CMP #'a'               \ If key is less than 'A', it is invalid, so jump to
 BCC add6               \ add6 to make an error beep and return from the
                        \ subroutine

 CMP #'x'               \ If key is 'X' or greater, it is invalid, so jump to
 BCS add6               \ add6 to make an error beep and return from the
                        \ subroutine

                        \ Key is 'A' to 'W' (which includes the Elite logo as
                        \ 'W')

 SBC #'a'-11            \ Otherwise calculate ship type with 'A' giving 10 (the
                        \ C flag is clear for this calculation, hence the 11)

ELIF _MASTER_VERSION

 CMP #'A'               \ If key is less than 'A', it is invalid, so jump to
 BCC add6               \ add6 to make an error beep and return from the
                        \ subroutine

 CMP #'W'               \ If key is 'W' or greater, it is invalid, so jump to
 BCS add6               \ add6 to make an error beep and return from the
                        \ subroutine

                        \ Key is 'A' to 'V' (which does not include the Elite
                        \ logo)

 SBC #'A'-11            \ Otherwise calculate ship type with 'A' giving 10 (the
                        \ C flag is clear for this calculation, hence the 11)

ENDIF

 BCS add4               \ Jump to add4 (this BCS is effectively a JMP as the C
                        \ flag will be set from the subtraction)

.add2

                        \ Key is '1' to '9'

 CMP #'2'               \ If key is '2' then we reuse this for the Cougar (as
 BNE add3               \ the value of 2 would otherwise be the space station),
 LDA #'0' + COU         \ so set A so the subtraction gives us the type in COU

.add3

 SEC                    \ Calculate the ship type from the key pressed
 SBC #'0'

.add4

 PHA
 JSR PrintShipType      \ Print the current ship type on the screen to remove it
 PLA

 STA TYPE               \ Store the new ship type

 JSR ZINF               \ Call ZINF to reset INWK and the orientation vectors

 JSR InitialiseShip     \ Initialise the ship coordinates

 JSR CreateShip         \ Create the new ship

 JMP PrintShipType      \ Print the current ship type on the screen and return
                        \ from the subroutine using a tail call

.add6

 JMP MakeErrorBeep      \ Make an error beep and return from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: FireLaser
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Fire the current ship's laser
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.FireLaser

 CPX #2                 \ If this is the station or planet, jump to
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't fire their lasers

 LDA INWK+31            \ Toggle bit 6 in byte #31 to denote that the ship is
 EOR #%01000000         \ firing its laser at us (or to switch it off)
 STA INWK+31

 JMP DrawShip+3         \ Draw the ship (but not on the scanner), returning from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: ExplodeShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Explode the current ship
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.ExplodeShip

 CPX #2                 \ If this is the station or planet, jump to 
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't explode them

 LDA #&A5               \ Re-enable DOEXP
 STA DOEXP+9

 LDA INWK+31            \ If bit 5 of byte #31 is set, then the ship is already
 AND #%00100000         \ exploding, so jump to expl1 to move the explosion on
 BNE expl1              \ by one step

 JSR MV5                \ Draw the current ship on the scanner to remove it

 LDA INWK+31            \ Set bit 7 and clear bit 5 in byte #31 to denote that
 ORA #%10000000         \ the ship is exploding
 AND #%11101111
 STA INWK+31

 JSR DrawShip+3         \ Draw the explosion (but not on the scanner) to get it
                        \ going (as only calling this once at the start of a new
                        \ explosion doesn't show a lot)

.expl1

 JSR DrawShip+3         \ Draw the explosion (but not on the scanner)

 LDA #&60               \ Disable DOEXP again
 STA DOEXP+9

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CreateShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Create a ship
\
\ ******************************************************************************

.CreateShip

 LDA TYPE               \ Fetch the type of ship to create

 JSR NWSHP              \ Add the new ship and store it in K%

 BCC MakeErrorBeep      \ If ship was not added, jump to MakeErrorBeep to make
                        \ an error beep and return from the subroutine using a
                        \ tail call

 JSR GetCurrentSlot     \ Set X to the slot number of the new ship

 BCS MakeErrorBeep      \ If we didn't find the slot, jump to MakeErrorBeep to
                        \ make an error beep and return from the subroutine
                        \ using a tail call

 JSR UpdateSlotNumber   \ Store and print the new slot number in X

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

 JMP DrawShip           \ Draw the ship, returning from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: MakeErrorBeep
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Make an error beep
\
\ ******************************************************************************

.MakeErrorBeep

IF _6502SP_VERSION

 LDA #40                \ Call the NOISE routine with A = 40 to make a low,
 JMP NOISE              \ long beep, returning from the subroutine using a tail
                        \ call

ELIF _MASTER_VERSION

 LDY #0                 \ Call the NOISE routine with Y = 0 to make a long, low
 JMP NOISE              \ beep, returning from the subroutine using a tail call

ENDIF

\ ******************************************************************************
\
\       Name: CopyShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Duplicate the ship in the current slot
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.CopyShip

 CPX #2                 \ If this is the station or planet, jump to
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't duplicate them

 LDA INWK+3             \ Move the current away from the origin a bit so the new
 CLC                    \ ship doesn't overlap the original ship
 ADC #10
 STA INWK+3
 BCC P%+4
 INC INWK+3

 JSR CreateShip         \ Create a new ship of the same type

 JMP HighlightShip      \ Highlight the new ship, so we can see which one it is,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: DeleteShip
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Delete the ship from the current slot
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   Slot number
\
\ ******************************************************************************

.DeleteShip

 CPX #2                 \ If this is the station or planet, jump to
 BCC MakeErrorBeep      \ MakeErrorBeep as you can't delete them

 JSR EraseShip          \ Erase the current ship from the screen

 LDX currentSlot        \ Delete the current ship, shuffling the slots down
 JSR KILLSHP

 LDX currentSlot        \ If the current slot is still full, jump to delt1 to
 LDA FRIN,X             \ keep this as the current slot
 BNE delt1

 DEX                    \ If we get here we just emptied the last slot, so
                        \ switch to the previous slot

.delt1

 JMP SwitchToSlot       \ Switch to slot X to load the new ship's data,
                        \ returning from the subroutine using a tail call


\ ******************************************************************************
\
\       Name: TargetMissile
\       Type: Subroutine
\   Category: Universe editor
\    Summary: Set the target for a missile
\
\ ******************************************************************************

.TargetMissile

 LDX TYPE               \ If this is not a missile, jump to MakeErrorBeep to
 CPX #MSL               \ make an error beep and return from the subroutine
 BNE MakeErrorBeep      \ using a tail call

 LDA #7                 \ Print extended text token 7 ("SLOT?") as a prompt
 JSR PrintPrompt

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A (and X)

 CMP #'0'               \ If the key pressed is outside the range 0 to 9, jump
 BCC miss5              \ to miss5 to make an error beep and return from the
 CMP #'9'+1             \ subroutine
 BCS miss5

 SEC                    \ Convert the value from ASCII to a number, 0 to 9
 SBC #'0'

 PHA                    \ Check whether SHIFT is being held down
 JSR CheckShiftCtrl
 PLA

 BIT shiftCtrl          \ If not, jump to miss1 to skip the following 
 BPL miss1    

 CLC                    \ SHIFT is being held down, so add 10 to the slot number
 ADC #10

.miss1

 CMP #0                 \ If the number entered is 0 (the planet), jump to miss4
 BEQ miss4              \ to target our ship

                        \ We now have the slot number in A, so we add it as the
                        \ missile target

 ASL A                  \ Shift the target number left so it's in bits 1-5

 ORA #%10000000         \ Store the target number in the missile's AI byte, with
                        \ bit 7 set so AI is enabled

.miss2

 PHA                    \ Store the new INWK+32 byte on the stack

 JSR PrintShipType      \ Print the old target on the screen to remove it

 PLA                    \ Update the new INWK+32 byte
 STA INWK+32

 JSR PrintShipType      \ Print the new target on the screen

 JSR BEEP               \ Make a confirmation beep

 JSR STORE              \ Call STORE to copy the ship data block at INWK back to
                        \ the K% workspace at INF

.miss3

 LDA #7                 \ Print extended text token 7 ("SLOT?") as a prompt to
 JMP PrintPrompt        \ remove it, and return from the subroutine using a tail
                        \ call

.miss4

 LDA #%11000000         \ Set bit 7 of INWK+32 to make the missile hostile, so
                        \ it targets our ship, with bit 7 set so AI is enabled

 BNE miss2              \ Jump to miss2 to store the new INWK+32 (this BNE is
                        \ effectively a JMP as A is never zero)

.miss5

 JSR MakeErrorBeep      \ Make an error beep

 JMP miss3              \ Jump to miss3 to remove the prompt

.endUniverseEditor2
