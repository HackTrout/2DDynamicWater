extends Area2D

#Drawing
export(bool) var draw_water = true
export(bool) var draw_points = false
export(bool) var draw_neighbouring_springs = false
export(bool) var draw_area = false

export(float) var draw_points_size = 5.0
export(float) var draw_spring_size = 3.0
export(float) var draw_spring_distance = 32.0

export(float) var mouse_apply_force = 64.0
export(float) var mouse_apply_width = 48.0

#Passive wave variables
export(bool) var waves_enabled = true #Whether passive waves are enabled or not
export(float) var wave_height = 4.0 #How high the passive waves are
export(float) var wave_speed = 4.0 #How quick they are
export(float) var wave_width = 16.0 #How wide they are

export(int) var wave_spread_amount = 4 #How many times forces should be calculated between neighbouring points per frame. Higher values means waves travel faster

export(int) var point_per_distance = 8 #A point will be created every nth units along the water's surface. More points means higher fidelity
var points = [] #The list of points along the water's surface

export(float, 0.0, 1.0, 0.001) var point_damping = 0.99 #This is multiplied with a point's motion every frame. Smaller values mean waves will fade quicker
export(float) var point_independent_stiffness = 1.0 #Stiffness between a point and it's resting y pos.
export(float) var point_neighbouring_stiffness = 2.0 #Stiffness between neighbouring points. Higher values mean motion is transferred between points quicker.

var collision_polygon : CollisionPolygon2D #A reference a CollisionPolygon2D.
var top_left_point : Vector2 #The top left point of the "collision_polygon"'s polygon
var top_right_point : Vector2 #The top tight point of the "collision_polygon"'s polygon

onready var water_point_scene := preload("res://FinishedTutorial/FinishedWater/FinishedWaterPoint/FinshedWaterPoint.tscn") #The scene for the points along the water's surface


func _ready():
	#Find a "CollisionPolygon2D" to use
	for child in get_children():
		#Check class of child
		if child.get_class() == "CollisionPolygon2D":
			if child.polygon.size() == 4:
				#Update reference
				collision_polygon = child
				
				#Assign Points
				top_left_point = collision_polygon.polygon[0]
				top_right_point = collision_polygon.polygon[1]
				
				#Create points along surface
				create_surface_points()
				
				#Stop loop
				break


func create_surface_points() -> void:
	#Create an Array of WaterPoints along the Surface
	var point_amount = int(floor((top_right_point.x - top_left_point.x) / point_per_distance))
	for i in range(point_amount):
		var point = water_point_scene.instance()
		add_child(point)
		
		point.damping = point_damping
		
		point.position = Vector2(top_left_point.x + (point_per_distance * (i + 0.5)), top_left_point.y)
		points.append(point)


func destroy_surface_points() -> void:
	#Destroy WaterPoints along the Surface
	for point in points:
		point.queue_free()
	points.clear()


var delta_time = 0.0
func _physics_process(delta) -> void:
	#Delta Time
	if waves_enabled:
		delta_time += delta
		if delta_time > PI * 2.0:
			delta_time -= PI * 2.0
	
	#Update Points
	if collision_polygon != null:
		var target_y = global_position.y + top_left_point.y
		for i in range(points.size()):
			#Calculate Motion for Point
			var point = points[i]
			point.motion += point.calculate_motion(Vector2(point.global_position.x, target_y), point_independent_stiffness)
			
			#Add Some Wave
			if waves_enabled:
				point.motion.y += sin(((i / float(points.size())) * wave_width) + (delta_time * wave_speed)) * (wave_height + rand_range(-2, 2))
			
			#Apply spring forces between neighbouring points
			for j in range(wave_spread_amount):
				#Point to Left
				if i - 1 >= 0:
					var left_point = points[i - 1]
					point.motion += point.calculate_motion(Vector2(point.global_position.x, left_point.global_position.y), point_neighbouring_stiffness)
				
				#Point to Right
				if i + 1 < points.size():
					var right_point = points[i + 1]
					point.motion += point.calculate_motion(Vector2(point.global_position.x, right_point.global_position.y), point_neighbouring_stiffness)
	
	#Apply force at mouse position
	if Input.is_action_just_pressed("ui_accept"):
		apply_force(get_global_mouse_position(), mouse_apply_force * Vector2.DOWN, mouse_apply_width)
	
	#Draw Points
	update()


func apply_force(pos: Vector2, force: Vector2, width: float = 16.0) -> void:
	#Ignore if pos is outside area
	if (points[0].global_position.x - width) > pos.x || (points[points.size() - 1].global_position.x + width) < pos.x:
		return
	
	#Convert global coords to local coords
	var local_pos = to_local(pos)
	
	#Find the furthest positions that could be affected to the left and right
	var left_most = local_pos.x - (width / 2.0)
	var right_most = local_pos.x + (width / 2.0)
	
	#Convert those local positions to indices in the "points" array
	var left_most_index = get_index_from_local_pos(Vector2(left_most, local_pos.y))
	var right_most_index = get_index_from_local_pos(Vector2(right_most, local_pos.y))
	
	#Run through the indices and apply the force
	for i in range(left_most_index, right_most_index + 1):
		points[i].motion += force


func get_index_from_local_pos(pos: Vector2) -> int:
	#Returns an index of the "points" array on water's surface to the local pos
	var index = floor((abs(top_left_point.x - pos.x) / (top_right_point.x - top_left_point.x)) * points.size())
	
	#Ensure the index is a possible index of the array
	return int(clamp(index, 0, points.size() - 1))


func _draw() -> void:
	#Draw Points
	if collision_polygon != null:
		if draw_area:
			var area = collision_polygon.polygon
			var col = Color(0.0, 0.0, 1.0, 0.25)
			draw_polygon(area, [col, col, col, col])
		
		if draw_water:
			var surface = [top_left_point]
			var polygon = [top_left_point]
			var colors = [Color.blue]
			for i in range(points.size()):
				#Append points
				surface.append(points[i].position)
				polygon.append(points[i].position)
				colors.append(Color.blue)
			
			surface.append(top_right_point)
			
			polygon.append(top_right_point)
			colors.append(Color.blue)
			polygon.append(collision_polygon.polygon[2])
			colors.append(Color.blue)
			polygon.append(collision_polygon.polygon[3])
			colors.append(Color.blue)
			
			draw_polygon(polygon, colors)
			draw_polyline(surface, Color.lightblue, 5.0)
		
		if draw_points:
			var target_y = top_left_point.y
			for i in range(points.size()):
				var point = points[i]
				draw_circle(point.position, draw_points_size, Color.white)
				
				#Draw Spring
				var w = 1.0 - (abs(point.position.y - target_y) / draw_spring_distance)
				draw_line(point.position, Vector2(point.position.x, target_y), Color.white, draw_spring_size * w)
				
				#Draw Neighbouring Springs
				if draw_neighbouring_springs:
					#Point to Left
					if i - 1 >= 0:
						var left_point = points[i - 1]
						var lw = 1.0 - (abs(point.position.y - left_point.position.y) / draw_spring_distance)
						draw_line(point.position, left_point.position, Color.white, draw_spring_size * lw)
					
					#Point to Right
					if i + 1 < points.size():
						var right_point = points[i + 1]
						var rw = 1.0 - (abs(point.position.y - right_point.position.y) / draw_spring_distance)
						draw_line(point.position, right_point.position, Color.white, draw_spring_size * rw)
