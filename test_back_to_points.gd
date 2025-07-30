# Test script for back-to point system
extends Node

func test_back_to_points():
	print("=== TESTING BACK-TO POINT SYSTEM ===")
	
	# Find the friend
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	if friend_nodes.size() > 0:
		var friend = friend_nodes[0]
		print("✓ Friend found: ", friend.name)
		
		# Test if friend has the back-to point system
		if friend.has_method("track_movement_for_back_to_points"):
			print("✓ Friend has track_movement_for_back_to_points method")
		else:
			print("✗ Friend missing track_movement_for_back_to_points method")
		
		if friend.has_method("determine_departure_target"):
			print("✓ Friend has determine_departure_target method")
		else:
			print("✗ Friend missing determine_departure_target method")
		
		# Test the departure target determination
		var departure_target = friend.determine_departure_target()
		print("Departure target: ", departure_target)
		
	else:
		print("✗ No friend found in scene")
	
	print("=== BACK-TO POINT TEST COMPLETE ===")

func test_movement_tracking():
	print("=== TESTING MOVEMENT TRACKING ===")
	
	# Find the friend
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	if friend_nodes.size() > 0:
		var friend = friend_nodes[0]
		print("✓ Friend found: ", friend.name)
		
		# Check current back-to points
		if friend.has_method("track_movement_for_back_to_points"):
			print("Current back-to points: ", friend.back_to_points)
			print("Last position: ", friend.last_position)
			print("Half screen distance: ", friend.half_screen_distance)
		else:
			print("✗ Friend missing track_movement_for_back_to_points method")
	else:
		print("✗ No friend found in scene")
	
	print("=== MOVEMENT TRACKING TEST COMPLETE ===") 