extends GutTest

func _fixture() -> Dictionary:
	return {
		"questions": [{"id": "rbc-0001", "topic": "rbc", "subtopic": "microcytic", "difficulty": 2,
			"kind": "theoretical", "stem": "Which finding fits?", "image": null,
			"choices": ["Iron depletion", "Vitamin B12 depletion", "Acute blood loss", "Renal failure"],
			"answer": 0, "explanation": "Iron depletion causes microcytosis.", "source": "iron"}],
		"morph": {}, "photos": [], "coag_cases": [], "diff_profiles": [],
		"cbc_cases": [{"id": "cbc-001", "topic": "rbc", "subtopic": "microcytic", "difficulty": 2,
			"sex": "F", "age": 34, "vignette": "An adult has anemia.", "spurious": false,
			"cbc": {"WBC": 6.0, "RBC": 4.0, "HGB": 12.0, "HCT": 36.0,
				"MCV": 90.0, "MCH": 30.0, "MCHC": 33.3, "RDW": 13.0, "PLT": 250},
			"smear": [], "steps": [_step(), _step()], "source": "iron"}], "errors": [],
		"sources": {"iron": {"title": "Iron Deficiency Anemia", "publisher": "StatPearls (NCBI Bookshelf)",
			"url": "https://www.ncbi.nlm.nih.gov/books/NBK448065/", "keyword": "iron deficiency"}},
		"generated_sources": _generated(),
	}

func _generated() -> Dictionary:
	var generated: Dictionary = {}
	for key: String in ContentValidator.GENERATED_SOURCE_KEYS:
		generated[key] = "iron"
	return generated

func _step() -> Dictionary:
	return {"stem": "What is the next step?", "choices": ["Review", "Discard", "Dilute", "Warm"],
		"answer": 0, "explanation": "Review the findings first."}

func _contains(errors: Array[String], part: String) -> bool:
	for error: String in errors:
		if part in error:
			return true
	return false

func test_wrong_answer_index_is_reported_with_file_and_id() -> void:
	var c: Dictionary = _fixture()
	c["questions"][0]["answer"] = 4
	var errors: Array[String] = ContentValidator.validate(c)
	assert_true(_contains(errors, "data/questions/rbc.json [rbc-0001]: answer"))

func test_unknown_subtopic_is_reported_with_file_and_id() -> void:
	var c: Dictionary = _fixture()
	c["questions"][0]["subtopic"] = "not_a_subtopic"
	var errors: Array[String] = ContentValidator.validate(c)
	assert_true(_contains(errors, "data/questions/rbc.json [rbc-0001]: unknown subtopic"))

func test_inconsistent_mcv_is_reported_with_file_and_id() -> void:
	var c: Dictionary = _fixture()
	c["cbc_cases"][0]["cbc"]["MCV"] = 60.0
	var errors: Array[String] = ContentValidator.validate(c)
	assert_true(_contains(errors, "data/cases_cbc.json [cbc-001]: inconsistent MCV"))

func test_consistent_indices_do_not_produce_index_errors() -> void:
	var errors: Array[String] = ContentValidator.validate(_fixture())
	assert_false(_contains(errors, "inconsistent MCV"))
	assert_false(_contains(errors, "inconsistent MCH"))

func test_spurious_case_is_exempt_from_index_consistency() -> void:
	var c: Dictionary = _fixture()
	c["cbc_cases"][0]["spurious"] = true
	c["cbc_cases"][0]["cbc"]["MCV"] = 60.0
	assert_false(_contains(ContentValidator.validate(c), "inconsistent MCV"))

func test_duplicate_ids_across_questions_and_cases_are_rejected() -> void:
	var c: Dictionary = _fixture()
	c["cbc_cases"][0]["id"] = "rbc-0001"
	assert_true(_contains(ContentValidator.validate(c), "duplicate id"))

func test_unknown_image_and_duplicate_choices_are_rejected() -> void:
	var c: Dictionary = _fixture()
	c["questions"][0]["image"] = "unknown_cell"
	c["questions"][0]["choices"][1] = "Iron depletion"
	var errors: Array[String] = ContentValidator.validate(c)
	assert_true(_contains(errors, "unknown image morphology"))
	assert_true(_contains(errors, "choices must be distinct"))

func test_coag_requires_pt_and_inr_together() -> void:
	var c: Dictionary = _fixture()
	c["coag_cases"] = [{"id": "coag-001", "topic": "hemo", "subtopic": "pt_inr", "difficulty": 1,
		"sex": "M", "age": 22, "vignette": "The PT was requested.", "results": {"PT": 12.0, "INR": null},
		"steps": [_step(), _step()], "source": "iron"}]
	assert_true(_contains(ContentValidator.validate(c), "INR must be non-null if and only if PT is non-null"))

func test_invalid_differential_sum_and_class_are_rejected() -> void:
	var c: Dictionary = _fixture()
	c["diff_profiles"] = [{"id": "bad", "pct": {"seg": 90, "unknown": 5}}]
	var errors: Array[String] = ContentValidator.validate(c)
	assert_true(_contains(errors, "unknown differential class"))
	assert_true(_contains(errors, "pct must sum to exactly 100"))

func test_photo_morphology_and_file_must_exist() -> void:
	var c: Dictionary = _fixture()
	c["photos"] = [{"id": "missing", "morph": "unknown", "file": "res://assets/photos/does_not_exist.jpg"}]
	var errors: Array[String] = ContentValidator.validate(c)
	assert_true(_contains(errors, "data/photos.json [missing]: unknown morphology"))
	assert_true(_contains(errors, "photo file does not exist"))

func test_cbc_minimum_is_30_not_33_and_lab_is_optional() -> void:
	var c: Dictionary = _fixture()
	c["cbc_cases"] = []
	for index: int in range(30):
		var item: Dictionary = _fixture()["cbc_cases"][0].duplicate(true)
		item["id"] = "cbc-%03d" % (index + 1)
		if index < 14:
			item["topic"] = "rbc"
			item["subtopic"] = "microcytic"
		elif index < 26:
			item["topic"] = "wbc"
			item["subtopic"] = "benign_myeloid"
		else:
			item["topic"] = "plt"
			item["subtopic"] = "thrombocytopenia"
		c["cbc_cases"].append(item)
	var errors: Array[String] = ContentValidator.validate(c)
	assert_false(_contains(errors, "data/cases_cbc.json [bank]"))

func test_fixture_with_valid_sources_has_no_source_errors() -> void:
	assert_false(_contains(ContentValidator.validate(_fixture()), "source"))

func test_unknown_question_source_is_reported() -> void:
	var c: Dictionary = _fixture()
	c["questions"][0]["source"] = "nope"
	assert_true(_contains(ContentValidator.validate(c), "data/questions/rbc.json [rbc-0001]: unknown source nope"))

func test_missing_case_source_is_reported() -> void:
	var c: Dictionary = _fixture()
	c["cbc_cases"][0].erase("source")
	assert_true(_contains(ContentValidator.validate(c), "data/cases_cbc.json [cbc-001]: missing source"))

func test_unknown_step_source_is_reported() -> void:
	var c: Dictionary = _fixture()
	c["cbc_cases"][0]["steps"][1]["source"] = "nope"
	assert_true(_contains(ContentValidator.validate(c), "data/cases_cbc.json [cbc-001] step 2: unknown source nope"))

func test_source_urls_must_be_https_on_allow_listed_hosts() -> void:
	var rejected: Array[String] = [
		"https://example.com/page", "http://www.ncbi.nlm.nih.gov/books/NBK448065/",
		"https://evilnih.gov/page", "https://nih.gov.evil.com/page", "https://user@nih.gov/page",
		"https://example.com\\.nih.gov/page", "https://example.com .nih.gov/page",
	]
	for url: String in rejected:
		var c: Dictionary = _fixture()
		c["sources"]["iron"]["url"] = url
		assert_true(_contains(ContentValidator.validate(c), "data/sources.json [iron]: url must be"), url)
	var accepted: Array[String] = ["https://www.ncbi.nlm.nih.gov/books/NBK448065/", "https://nih.gov/x", "https://medlineplus.gov/a?b=1"]
	for url: String in accepted:
		var c: Dictionary = _fixture()
		c["sources"]["iron"]["url"] = url
		assert_false(_contains(ContentValidator.validate(c), "url must be"), url)

func test_unused_source_is_reported() -> void:
	var c: Dictionary = _fixture()
	c["sources"]["extra"] = c["sources"]["iron"].duplicate()
	assert_true(_contains(ContentValidator.validate(c), "data/sources.json [extra]: unused source"))

func test_missing_and_unexpected_generated_keys_are_reported() -> void:
	var c: Dictionary = _fixture()
	c["generated_sources"].erase("qc:westgard")
	c["generated_sources"]["drill:bogus"] = "iron"
	var errors: Array[String] = ContentValidator.validate(c)
	assert_true(_contains(errors, "data/sources.json [generated]: missing key qc:westgard"))
	assert_true(_contains(errors, "data/sources.json [generated]: unexpected key drill:bogus"))
