# 2DDynamicWater
2D Dynamic Water for use in 2D Godot games.

This project has two scenes, the water and waterpoints. Waterpoints make up the surface and the water creates and calculates the motion for the points.
The code has plenty of comments which should help you understand how it works.

Note, when adding a shape to the water, which is an area2D, add a CollisionPolygon2D. Have point 0 be the top left, point 1 be the top right, point 2 be the bottom right and point 3 be the bottom left.

Free to use in your own projects.
