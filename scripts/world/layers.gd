class_name Layers
extends RefCounted
## Physics collision layer bits, in one place so every body agrees.

const WALLS := 1
const BUDDY := 2
const OBJECTS := 4
## What the Hand can pick up.
const GRABBABLE := BUDDY | OBJECTS
## What counts as something to stand on.
const GROUND := WALLS | OBJECTS
