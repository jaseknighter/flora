
![](images/three_plants_inv.png)

# Flora - beta

l-systems sequencer and bandpass filtered sawtooth engine for monome norns

- [Flora - beta](#flora---beta)
  * [Overview](#overview)
    + [L-systems and their sequencing](#l-systems-and-their-sequencing)
      - [L-system basics](#l-system-basics)
      - [Simple rewriting example](#simple-rewriting-example)
      - [Sequencing the L-system](#sequencing-the-l-system)
        * [The Flora alphabet](#the-flora-alphabet)
        * [Changes in pitch](#changes-in-pitch)
    + [Bandsaw](#bandsaw)
  * [Requirements](#requirements)
  * [Instructions for Norns](#instructions-for-norns)
    + [Pages](#pages)
      - [Plant](#plant)
      - [Modify](#modify)
      - [Observe](#observe)
      - [Plow](#plow)
      - [Water](#water)
    + [Generating new L-system axioms and rulesets](#generating-new-l-system-axioms-and-rulesets)
  * [Roadmap](#roadmap)
  * [Credits](#credits)
  * [References](#references)

## Overview
### L-systems and their sequencing
#### L-system basics
An L-system is a parallel rewriting mechanism originally conceived by Aristid Lindenmayer in 1968 as a mathematical model of plant development. 

The basic building blocks of most L-systems include:

* Turtle graphics engine: First developed for the Logo programming language, a turtle creates a drawing from instructions that dictate when to move forward and draw and when to rotate to point in a different direction.
* Alphabet: A set of characters, each representing an instruction for an L-system algorithm to interpret (e.g. rotate, move forward, turn around, draw a line, etc.).
* Axiom: A sentence containing one or more characters that represents the starting point of an L-system algorithm.
* Rulesets: Each ruleset of an L-system contains two sentences. The first sentence typically contains a single character. The second sentence contains one or more character. Each time the algorithm runs, if the character contained in the first sentence of the ruleset is encountered, it will replace that character with the character(s) of the second sentence. 
* Angle: An angle used by the turtle to rotate clockwise or counterclockwise, giving it a new direction to move the next time it receives an instruction to draw a line.
* Generations: A generation represents a completed execution of the L-system algorithm.
#### Simple rewriting example 

Take the following: 
* Axiom: b
* Ruleset 1: b->a 
* Ruleset 2: a->ab 

The above axiom and rulesets will result in the following sentences when run 5 times, starting with the axiom 'b' as Generation 0. Ruleset 1 states that each time the character 'b' is encountered, it is replaced with 'a.' Ruleset 2 states that each time the character 'a' is encountered, it replaced with 'ab.'

* Generation 0: b 
* Generation 1: a 
* Generation 2: ab
* Generation 3: aba
* Generation 4: abaab
* Generation 5: abaababa


#### Sequencing the L-system

##### The Flora alphabet



]: restore the previously saved position
+: rotate clockwise (by t.theta)
-: rotate counterclockwise (by -t.theta)
f: move forward without drawing
|: turn around 180 degrees


| Character | Turtle Behavior | Sound Behavior  |
| ---------- | --------------- | --------------- |
| F   | Move the turtle forward and draw a line and a circle    | Play current note |
| G   | Move the turtle forward and draw a line | Resting note (silence)    |
| \[   | Save the current position    | Save the current note     |
| ]   | Restore the last saved position    | Restore the last saved note   |
| +   | Rotate the turtle clockwise by the current angle    | Increase the active note (see Changes in pitch below) |
| -   | Rotate the turtle counterclockwise by the current angle     | Increase the active note (see *Changes in pitch below*) |
| \|   | Rotate the turtle 180 degrees   | No sound behavior    |
| other | Other characters used in axioms and rulesets are ignored by the turtle | No sounds behavior |

##### Changes in pitch
Flora leverages L-systems to algorithmically generate music, taking the angles written into L-system sentences as indicators of an increase or decrease in pitch. The amount of change in pitch is set by the angle measured in radians multiplied by the current pitch. Currently, the changes in pitch are quantized, so if an angle multiplied by the current pitch is not greater than a whole number, the pitch stays the same. 

If a change in angle results in a pitch that is greater than the number of notes in the active scale, the active note becomes the root note of the active scale. Conversely, if a change in angle results in a pitch that is less than the root note of the active scale, the active note becomes the last note in the active scale.

### Bandsaw
## Requirements

## Instructions for Norns
Basic instructions
### Pages
#### Plant
#### Modify
#### Observe
#### Plow
#### Water

### Generating new L-system axioms and rulesets

## Roadmap

## Credits
Flora's L-system code is a Lua-translation of the code presented in Daniel Shiffman's [The Nature of Code](https://natureofcode.com/book/chapter-8-fractals/)

*Bandsaw*, the bandpass-filtered sawtooth engine is based on Eli Fieldsteel's marimba presented in his [SuperCollider Tutorial #15: Composing a Piece, Part I](https://youtu.be/lGs7JOOVjag)
## References

