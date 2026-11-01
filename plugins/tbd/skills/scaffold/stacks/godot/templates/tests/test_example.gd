extends RefCounted

## Shape of a suite: a `run(t)` that calls one function per behaviour. Register
## new suites in `run_all.gd`. Delete this one once a real suite exists.


func run(t: TestCase) -> void:
	_test_typed_arrays(t)


func _test_typed_arrays(t: TestCase) -> void:
	t.test("typed arrays are built by appending")
	# Assigning Dictionary.keys() straight to an Array[String] throws at runtime,
	# and inside _initialize that presents as a silent hang. Append instead.
	var names: Array[String] = []
	for key in {"a": 1, "b": 2}.keys():
		names.append(key)
	t.eq(names.size(), 2)
	t.eq(names[0], "a")
