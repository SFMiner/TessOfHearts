# Test script for friend departure functionality
extends Node

func test_friend_departure():
	print("=== TESTING FRIEND DEPARTURE ===")
	
	# Find the friend
	var friend_nodes = get_tree().get_nodes_in_group("Friend")
	if friend_nodes.size() > 0:
		var friend = friend_nodes[0]
		print("Friend found: ", friend.name)
		
		# Test if friend has the depart_from_screen method
		if friend.has_method("depart_from_screen"):
			print("✓ Friend has depart_from_screen method")
			
			# Test the departure direction determination
			if friend.has_method("determine_departure_direction"):
				print("✓ Friend has determine_departure_direction method")
				var direction = friend.determine_departure_direction()
				print("Departure direction: ", direction)
			else:
				print("✗ Friend missing determine_departure_direction method")
		else:
			print("✗ Friend missing depart_from_screen method")
	else:
		print("✗ No friend found in scene")
	
	print("=== FRIEND DEPARTURE TEST COMPLETE ===")

func test_dialogue_choice():
	print("=== TESTING DIALOGUE CHOICE ===")
	
	# Find the dialogue system
	var dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if dialogue_system:
		print("✓ Dialogue system found")
		
		# Test if the excuse_me choice is handled
		if dialogue_system.has_method("trigger_excuse_friend_effects"):
			print("✓ Dialogue system has trigger_excuse_friend_effects method")
		else:
			print("✗ Dialogue system missing trigger_excuse_friend_effects method")
	else:
		print("✗ No dialogue system found")
	
	print("=== DIALOGUE CHOICE TEST COMPLETE ===") 