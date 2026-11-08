class_name SafetyScenarios
extends RefCounted
## Illustrated lab incidents: a vignette, then two or three decisions. Step dictionaries
## are shaped like question-bank entries so QuestionPanel can render them unchanged.

const SCENARIOS := [
	{
		"id": "safety-scn-mercury",
		"art": "mercury_spill",
		"title": "Mercury thermometer break",
		"difficulty": 2,
		"vignette": "A glass thermometer rolls off the chemistry bench and breaks on the floor. Silver beads scatter across the tile and roll under the bench. Two coworkers are walking toward the area.",
		"steps": [
			{
				"stem": "What do you do first?",
				"choices": [
					"Keep everyone out of the area and tell your supervisor a mercury spill has occurred",
					"Pour kitty litter over the beads so nobody slips",
					"Vacuum the beads up quickly before they spread further",
					"Sweep the beads into a dustpan and bag them",
				],
				"answer": 0,
				"explanation": "Clear people out of the area first: shoes carry mercury out of the room, and the spill has to be reported before cleanup starts. Vacuuming puts mercury vapour into the air you breathe, a broom breaks the beads into smaller droplets that travel further, and absorbent litter neither contains nor removes metallic mercury.",
				"source": "safety-epa-mercury-spill",
			},
			{
				"stem": "The mercury spill kit is open. How are the beads collected?",
				"choices": [
					"Wipe each bead up with alcohol gauze",
					"Roll the beads together with stiff cardboard, lift them with the eyedropper onto a damp paper towel, and seal everything in a labelled bag",
					"Rinse the beads into the sink with plenty of water",
					"Push the beads into a dustpan with a brush",
				],
				"answer": 1,
				"explanation": "Beads are rolled together with stiff cardboard and drawn up with an eyedropper onto a damp paper towel, then sealed in a labelled zip bag. Brushing or wiping breaks the mercury into smaller beads that scatter, and nothing goes into the drain: mercury lodges in the plumbing and keeps releasing vapour.",
				"source": "safety-epa-mercury-spill",
			},
			{
				"stem": "The beads are bagged. What happens next?",
				"choices": [
					"Drop the sealed bag in the red biohazard bag",
					"Put it in the regular trash now that it is sealed",
					"Keep the area ventilated to the outside and route the sealed waste to hazardous chemical waste through the laboratory's waste authority",
					"Pour any residue down the drain and wipe the floor dry",
				],
				"answer": 2,
				"explanation": "Keep the area ventilated to the outside for at least 24 hours afterwards, and contact the local health department or waste authority for disposal of the sealed bag as hazardous chemical waste. A red bag is for infectious waste, the regular trash sends mercury to landfill, and the drain is the one route that cannot be undone.",
				"source": "safety-epa-mercury-spill",
			},
		],
	},
	{
		"id": "safety-scn-xylene",
		"art": "chem_spill",
		"title": "Xylene on the bench",
		"difficulty": 2,
		"vignette": "A bottle tips on the staining bench. About 200 mL of xylene runs across the surface and drips onto the floor, and the smell fills the room within seconds.",
		"steps": [
			{
				"stem": "What is the first move?",
				"choices": [
					"Start mopping it up before it spreads to the floor drain",
					"Open a window and carry on with the staining run",
					"Alert your coworkers, keep them clear, and check the safety data sheet and the Chemical Hygiene Plan spill procedure before touching it",
					"Pour water over the spill to dilute it",
				],
				"answer": 2,
				"explanation": "Warn the people around you and find out what the plan and the safety data sheet require before you handle a flammable solvent spill — that is what tells you the PPE, the ignition sources to kill, and whether this volume is yours to clean at all. Mopping first commits you to the cleanup before you know any of it, and water spreads a solvent rather than diluting it.",
				"source": "safety-osha-lab-standard",
			},
			{
				"stem": "The spill is within what your training and the plan cover. How do you contain it?",
				"choices": [
					"Ring it with the inert absorbent from the chemical spill kit, working from the outside in, wearing the PPE the safety data sheet specifies",
					"Lay paper towels over it and drop them in the regular bin",
					"Hose it toward the floor drain",
					"Sweep it up while it is still wet",
				],
				"answer": 0,
				"explanation": "Work from the outer edge inward with the inert absorbent in the chemical spill kit so the spill stops growing, in the gloves and eye protection the safety data sheet lists in Section 8. Paper towels saturate and drip, and drains and brooms move the solvent somewhere worse.",
				"source": "safety-osha-lab-standard",
			},
			{
				"stem": "Where does the used absorbent go?",
				"choices": [
					"The red biohazard bag",
					"A labelled hazardous chemical waste container",
					"The autoclave",
					"The regular trash, once it has dried out",
				],
				"answer": 1,
				"explanation": "Absorbent soaked in xylene is hazardous chemical waste and goes into a labelled, compatible waste container under the Chemical Hygiene Plan. Letting it dry in the trash is the tempting shortcut and simply moves the evaporating solvent to a bin nobody is watching.",
				"source": "safety-osha-lab-standard",
			},
		],
	},
	{
		"id": "safety-scn-leak",
		"art": "water_leak",
		"title": "Leak under the sink",
		"difficulty": 1,
		"vignette": "Water is spreading across the floor from the trap under the laboratory sink. The puddle has already reached the walkway between the bench and the chemistry analyzer, and staff are stepping around it.",
		"steps": [
			{
				"stem": "What do you do?",
				"choices": [
					"Tighten the fitting yourself and dry the floor",
					"Mop it up and say nothing, since it is only water",
					"Leave it until the next shift and warn them verbally",
					"Keep people off the wet floor, mark or guard the area, and report the leak so it is repaired",
				],
				"answer": 3,
				"explanation": "Walking-working surfaces are kept clean and, so far as feasible, dry and free of hazards such as leaks and spills. Guard the area, keep staff off it, and report it so the leak is corrected. Mopping is tempting because the floor looks fine afterwards while the pipe keeps leaking under the cabinet.",
				"source": "safety-osha-walking-surfaces",
			},
			{
				"stem": "A colleague asks why 'I'll just fix the pipe myself' is the wrong answer.",
				"choices": [
					"Because the hazardous condition must be corrected or repaired before the surface is used again, and a repair of this kind belongs to a qualified person",
					"Because only the laboratory director may touch plumbing",
					"Because water on a laboratory floor counts as a biohazard",
					"Because the laboratory is not responsible for wet floors",
				],
				"answer": 0,
				"explanation": "The requirement is that the hazard be corrected or repaired before the walking surface is used again, and guarded until then — and repairs of this sort are done by a qualified person, not by whoever found the puddle. An improvised fix leaves the floor in service with a repair nobody has verified.",
				"source": "safety-osha-walking-surfaces",
			},
			{
				"stem": "The puddle has reached the power strip feeding the analyzer. Now what?",
				"choices": [
					"Unplug the strip wearing wet gloves",
					"Push the strip clear of the water with a chair",
					"Keep clear of the wet electrical equipment and have it de-energized before anyone works near it; wet or damaged cords come out of service",
					"Dry the strip with paper towels while it is still live",
				],
				"answer": 2,
				"explanation": "Nobody touches energized equipment standing in water: get it de-energized first, and take the wet cords and strip out of service rather than drying them off and plugging them back in. Unplugging it yourself with wet hands or nudging it with furniture both put a person in the circuit.",
				"source": "safety-osha-electrical-use",
			},
		],
	},
	{
		"id": "safety-scn-needlestick",
		"art": "needlestick",
		"title": "Needlestick at the draw station",
		"difficulty": 2,
		"vignette": "Transferring a used needle to the sharps container, you feel a sharp jab through the glove on your left index finger. The patient is still in the chair and the draw is only half finished.",
		"steps": [
			{
				"stem": "What do you do first?",
				"choices": [
					"Squeeze the finger to make it bleed freely",
					"Wash the site with soap and running water right away",
					"Apply bleach or another disinfectant to the puncture",
					"Finish the draw, then deal with the finger",
				],
				"answer": 1,
				"explanation": "Wash the exposed site with soap and water immediately — that is the first action after a percutaneous exposure. Squeezing the wound and applying caustic agents such as bleach are not recommended, and finishing the draw first delays both the wash and the reporting clock.",
				"source": "safety-niosh-bloodborne",
			},
			{
				"stem": "Next?",
				"choices": [
					"Wait until the end of the shift so the draw station is not left unattended",
					"Report it only if the patient is known to be positive",
					"Report immediately to your supervisor and occupational health so the exposure is evaluated and source testing can start",
					"Write it in your own notebook and watch for symptoms",
				],
				"answer": 2,
				"explanation": "Report at once: evaluation of the exposure, testing of the source patient, and any post-exposure prophylaxis are all time dependent, and PEP should start as soon as possible — within 72 hours of exposure. Waiting for the end of the shift or for a known-positive patient throws away the window in which prophylaxis works.",
				"source": "safety-cdc-hiv-pep",
			},
			{
				"stem": "What must the employer record?",
				"choices": [
					"An entry in the sharps injury log giving the device type and brand, the work area, and how the injury happened",
					"The employee's name on a log posted in the department",
					"Nothing, unless the employee later develops disease",
					"Only a note in the patient's chart",
				],
				"answer": 0,
				"explanation": "The sharps injury log records the type and brand of the device, the department or work area, and an explanation of how the incident occurred, maintained so individual privacy is protected; the confidential medical record holds the rest. A posted log with names does the opposite of what the standard requires.",
				"source": "safety-osha-bbp",
			},
		],
	},
	{
		"id": "safety-scn-centrifuge",
		"art": "centrifuge_break",
		"title": "Tube break in the centrifuge",
		"difficulty": 2,
		"vignette": "Halfway through a spin the centrifuge thuds and the note changes. It winds down, and through the lid you can see red fluid in the rotor well and a tube that is no longer whole.",
		"steps": [
			{
				"stem": "What do you do?",
				"choices": [
					"Open the lid immediately to see how bad the damage is",
					"Restart it so the run at least finishes",
					"Keep the lid closed and let the aerosols settle before opening it",
					"Reach in and lift out the rack so the rotor is not contaminated",
				],
				"answer": 2,
				"explanation": "A tube breaking at speed fills the bowl with infectious aerosol. Leave the lid closed and let it settle before opening, then open it wearing gloves and face protection. Opening at once puts your face directly over the aerosol you just generated.",
				"source": "safety-cdc-environmental-services",
			},
			{
				"stem": "With gloves and face protection on, how do you clear the glass?",
				"choices": [
					"Pick the pieces out by gloved hand and drop them in the red bag",
					"Rinse the bowl out at the sink",
					"Vacuum the bowl and wipe it dry",
					"Lift the fragments with forceps or a brush and dustpan into a sharps container, then disinfect the bowl",
				],
				"answer": 3,
				"explanation": "Contaminated broken glass is handled with mechanical means — forceps, or a brush and dustpan — into a puncture-resistant sharps container, and the rotor and bowl are then decontaminated. Gloved fingers are still fingers, and a red bag does not stop a shard.",
				"source": "safety-osha-bbp",
			},
		],
	},
	{
		"id": "safety-scn-eyesplash",
		"art": "eye_splash",
		"title": "Formalin in the eye",
		"difficulty": 1,
		"vignette": "Decanting formalin at the grossing bench, a coworker takes a splash behind their safety glasses. They are blinking hard, their eye is streaming, and they say it is stinging badly.",
		"steps": [
			{
				"stem": "What happens first?",
				"choices": [
					"Get them to the eyewash and flush for 15 minutes, holding the lids open",
					"Rinse the eye with a saline squeeze bottle for a minute",
					"Cover the eye with a pad and drive them to urgent care",
					"Wait a few minutes to see whether the stinging settles",
				],
				"answer": 0,
				"explanation": "Flush the eye immediately and keep flushing for about 15 minutes, holding the eyelids open so the chemical is washed from under them; then get medical attention. A quick squirt from a squeeze bottle or a trip across town with the chemical still in the eye both leave it burning for the whole journey.",
				"source": "safety-medlineplus-eye-emergencies",
			},
			{
				"stem": "Afterwards they ask why the eyewash is right there at the bench rather than in the first-aid room.",
				"choices": [
					"It is placed there for chemical hygiene audits",
					"Where eyes or body may be exposed to injurious corrosive materials, drenching or flushing facilities must be in the work area for immediate emergency use",
					"It is a convenience the laboratory chose to provide",
					"It is there so goggles are not needed at the bench",
				],
				"answer": 1,
				"explanation": "Suitable facilities for quick drenching or flushing of the eyes and body must be provided within the work area for immediate emergency use wherever injurious corrosive materials are handled. It is a requirement, not a courtesy — and it does not replace the eye protection that should have kept the splash out in the first place.",
				"source": "safety-osha-first-aid",
			},
		],
	},
	{
		"id": "safety-scn-fire",
		"art": "bench_fire",
		"title": "Flames on the bench",
		"difficulty": 2,
		"vignette": "Ethanol spilled beside a hot plate catches. A low flame spreads over about a hand's width of the bench top. Nobody is hurt, and the fire is not yet touching anything else.",
		"steps": [
			{
				"stem": "What is first?",
				"choices": [
					"Find the extinguisher before anyone else notices",
					"Raise the alarm and get people clear before deciding whether to fight it",
					"Open the hood sash to vent the smoke",
					"Pour water over the burning ethanol",
				],
				"answer": 1,
				"explanation": "Alarm and evacuation come before firefighting: the decision to use an extinguisher is only safe once people are leaving and the fire is still small. Hunting for the extinguisher first leaves the room unwarned, airflow feeds the fire, and water spreads burning solvent.",
				"source": "safety-osha-extinguishers",
			},
			{
				"stem": "You are trained, the alarm is raised, and the fire is still small. Which extinguisher?",
				"choices": [
					"A Class A water extinguisher",
					"A Class D unit for combustible metals",
					"An ABC or BC extinguisher, rated for flammable liquids",
					"A wet-chemical kitchen unit",
				],
				"answer": 2,
				"explanation": "Burning ethanol is a Class B flammable-liquid fire, so it needs a BC or multipurpose ABC extinguisher. Class A water units are for ordinary combustibles and will splash burning solvent around the bench; Class D is for combustible metals and wet chemical for cooking oils.",
				"source": "safety-osha-extinguishers",
			},
			{
				"stem": "Where do you aim?",
				"choices": [
					"At the base of the flames, sweeping from side to side",
					"At the top of the flames",
					"At the ceiling above the fire",
					"At the bench behind the fire, letting the agent roll forward",
				],
				"answer": 0,
				"explanation": "PASS: pull the pin, aim low at the base of the fire, squeeze the handle, and sweep from side to side. Aiming at the flames themselves wastes the agent in the air above the fuel that is actually burning.",
				"source": "safety-osha-extinguisher-use",
			},
		],
	},
]


## One scenario per run, chosen with rng.
static func pick(rng: RandomNumberGenerator) -> Dictionary:
	return SCENARIOS[rng.randi_range(0, SCENARIOS.size() - 1)]
