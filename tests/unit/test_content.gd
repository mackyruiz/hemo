extends GutTest

func test_real_content_loads_and_validates() -> void:
	var content: Dictionary = ContentLoader.load_all()
	assert_eq(content["errors"], [], "Every real content file must load")
	var errors: Array[String] = ContentValidator.validate(content)
	assert_eq(errors, [], "Real content must satisfy all schemas and bank coverage: %s" % "\n".join(errors))
