# Test script for excuse me functionality
extends Node

func test_excuse_me():
	print("=== TESTING EXCUSE ME FUNCTIONALITY ===")
	
	# Find the dialogue system
	var dialogue_system = get_tree().current_scene.find_child("DialogueSystem")
	if dialogue_system:
		print("✓ Dialogue system found")
		
		# Test the excuse me function directly
		if dialogue_system.has_method("test_excuse_me"):
			print("✓ Calling test_excuse_me function")
			dialogue_system.test_excuse_me()
		else:
			print("✗ test_excuse_me function not found")
	else:
		print("✗ No dialogue system found")
	
	print("=== EXCUSE ME TEST COMPLETE ===")

func test_choice_connection():
	print("=== TESTING CHOICE CONNECTION ===")
	
	# Find the choice UI
	var choice_ui = get_tree().current_scene.get_node_or_null("UI/DialogueChoiceUI")
	if choice_ui:
		print("✓ Choice UI found")
		print("Choice UI visible: ", choice_ui.visible)
		print("Choice UI is_showing: ", choice_ui.is_showing)
	else:
		print("✗ No choice UI found")
	
	print("=== CHOICE CONNECTION TEST COMPLETE ===") 