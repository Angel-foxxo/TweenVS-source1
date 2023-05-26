# TweenVS
![release](https://img.shields.io/github/v/release/Angel-foxxo/TweenVS-source1?style=flat-square)  

A simple VScript library for tweening and animating entities and variables.

## Usage
Include the `TweenVS.nut` file at the beginning of your script, done!  
Now you can create Tweens using the `TweenVS.Tween()` class

This library was mainly written for CS:GO but it has been tested with TF2 and should work for most Source Engine games.

## Documentation
See [Documentation.md](Documentation.md)

## Examples
TweenVS uses a cascading syntax, this allows you to chain methods to create animation sequences in a readable and concise manner.
### Tweening a variable
This code will take the value of `testVar` and interpolate to 10 in 2 seconds.
```cs
local testVar = 1;

TweenVS.Tween()
.from(testVar)//from the current value of `testVar`
.to(10, 2)//tween from the value of `testVar` to 10 in 2 seconds
.start();//start tweening
```
However this won't do much by itself, as it only takes in the value of `testVar` as REFERENCE and can't update the variable.  
In order to get the tweened value out, you can use the ``.on()`` function.  
This code will call the `testFunc` function and pass in the output value of the tween on `update`:
```cs
function testFunc(val)
{
    printl("Tweened value is: " + val);//print out the tweened value
}

local testVar = 1;

TweenVS.Tween()
.from(testVar)//from the current value of `testVar`
.to(10, 2)//tween from the value of `testVar` to 10
.start()//start tweening
.on("update", testFunc);//call the `testFunc` function with the output value
```
The code above can also be written like this, declaring the function in the tween body and putting 1 directly in `.to()` instead of using the variable:
```cs
TweenVS.Tween()
.from(1)
.to(10, 2)
.start()//start tweening
.on("update", function(val)
{
    printl("Tweened value is: " + val);//print out the tweened value

});
```
### Tweening an entity property
You can also pass an entity handle instead of a numeric value, accompanied by a property to tween.  
This code will make the player's view rotate 180 degrees on the y axis:  
```cs
local ply = Entities.FindByClassname(null, "player");

TweenVS.Tween()
.from(ply, "ang")//from current player angles
.toLocal(Vector(0, 180, 0), 2)//rotate 180 degrees on the y-axis local to the entity for 2 seconds
.start();//start tweening
```
While separating functions on new lines is recommended for readibility, you can also write the same setup like this:
```cs
local ply = Entities.FindByClassname(null, "player");

TweenVS.Tween().from(ply, "ang").toLocal(Vector(0, 180, 0), 2).start();
```
### Making it complicated.
Modifying the code from above, we can tweak the player's position in complex ways using just a few of the methods provided by the library.
```cs
local ply = Entities.FindByClassname(null, "player");

TweenVS.Tween()
.from(ply, "pos")//from current player position
.toLocal(Vector(0, 100, 0), 2)//move 100 units on the local y-axis in 2 seconds
.loop(5)//loop 5 times
.bounce()//reverse direction on every loop
.pause(1)//pause for 1 second before starting
.start()//start tweening
.easing(TweenVS.EaseInElastic);//use the "EaseInElastic" easing function
```
See [Documentation.md](Documentation.md) for a list of all functions.