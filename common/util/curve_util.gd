extends Object
class_name CurveUtil

static func flat_curve(vector: Vector2=Vector2.ONE) -> Curve:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0) * vector)
	curve.add_point(Vector2(1.0, 1.0) * vector)
	return curve

static func linear_curve(vector: Vector2=Vector2.ONE) -> Curve:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0) * vector)
	curve.add_point(Vector2(1.0, 1.0) * vector)
	return curve

static func bell_curve(vector: Vector2=Vector2.ONE) -> Curve:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0) * vector)
	curve.add_point(Vector2(0.5, 1.0) * vector)
	curve.add_point(Vector2(1.0, 0.0) * vector)
	return curve

static func average(curves: Array[Curve]) -> Curve:
	var averaged_curve = Curve.new()
	
	# Get the minimum and maximum position values from all curves (assuming uniform length)
	var num_points = 0
	for curve in curves:
		num_points = max(num_points, curve.get_point_count())
	
	# Loop through each point index
	for i in range(num_points):
		var total_x = 0.0
		var total_y = 0.0
		var total_in = 0.0
		var total_out = 0.0
		var valid_curves = 0
		
		# Sum up the values at each point for all curves
		for curve in curves:
			if i < curve.get_point_count():
				var point = curve.get_point_position(i)
				var in_tangent = curve.get_point_in(i)
				var out_tangent = curve.get_point_out(i)
				total_x += point.x
				total_y += point.y
				total_in += in_tangent
				total_out += out_tangent
				valid_curves += 1
		
		# Average the values and add the new point to the averaged curve
		if valid_curves > 0:
			var avg_x = total_x / valid_curves
			var avg_y = total_y / valid_curves
			var avg_in = total_in / valid_curves
			var avg_out = total_out / valid_curves
			averaged_curve.add_point(Vector2(avg_x, avg_y), avg_in, avg_out)
	
	return averaged_curve
