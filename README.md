First of all, massive credit to fvyshfinkle for helping me with this project. This project would not be where it is today without his help.

The current state of the engine is not final. This is an older build meant for demonstration purposes.

Currently, rendering is only supported using Advanced Peripherals augmented reality glasses. I do have plans to include plethora's goggles and also base computer craft monitors,
but those will come once the engine is in a more finalized state.

Currently the "scratch" engine is split up into 3 files:

Engine: This isn't anything important, actually. Really a demo of the API. This is what a file might look like when someone uses the API. Everything in there can be messed with.

3D_Tools: The "back end" of the engine. This handles all the math that 3D rendering involves. I can only recommend changing the object creation functions. Seriously, play around
  with those a little bit. The easiest thing to change is the color palette. Check out the tables used to store location data, rotations, stuff like that. That's how
  you'd animate or otherwise manipulate the objects once you've loaded them into an object list.
  
AR_Tools: One of the "front ends" of the engine. This handles breaking up triangles to rasterize, and actually draws them. I can't recommend messing with anything in here
  unless you are porting it to some other display.
  
Function documentation:
```
3D Tools:
screenTransform( objectData, display )
This handles the 3D matrix multiplication for manipulating objects. 
--objectData:
  An objects data table. Look at the newCube() function in 3D tools to see what this looks like.
--display:
  Your output screen's resolution in a `variable = { x = width *0.5, y = height *0.5 }` format.
  
newCube()
newSqr()
newTri()
Returns the default data of their corresponding object.
  Recommended variables to change:
  ...loc.x/y/z
  ...rot.x/y/z
  ...scale.x/y/z
  ...colorList
  
AR_Tools:
drawWireObj( arController,iL,vL,cL )
draws a wireframe object
--iL:
   index list. This is in included in an objects default data. Pass that in for the relevant object
      objList[name].indexList
--vL:
  vertice list. This is returned from the screenTransform() function. It contains every transformed vertice, as well as a back face culling flag list.
--cL:
  a color list. This is included in an objects default data. Pass that in for the relevant object
      objectList[name].colorList

drawSolidObj(  arController,iL,vL,cL )
  uses the same inputs as the wireframe function.
  ```
Example uses for every function:
See the ScratchEngine.Lua in the scratch engine folder
