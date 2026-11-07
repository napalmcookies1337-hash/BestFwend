class_name BuddyLines
extends RefCounted
## Everything the Buddy can say, by situation. Edit freely: the mind picks a line
## from the list for whatever just happened and avoids repeating recent ones.
## Every context below must have at least one line (a test checks).

const LINES := {
	&"spawn": [
		"Oh hey! New room?", "Hi! I'm your fwend!", "What a nice day to not get thrown.",
		"Hello! Please be gentle.", "Ooh, a window.", "Hey there, buddy. Hands where I can see 'em.",
	],
	&"respawn": [
		"I'm back! ...Wait, what happened?", "Whoa. Deja vu.", "Okay, fresh start. Be cool.",
		"Did I die? I feel like I died.", "New body, same bullshit.", "Huh. All my bits are back.",
	],
	&"grabbed": [
		"Hey!", "Whoa whoa whoa!", "Put me down!", "Where are we going?", "Hands off, pal!",
		"Uh oh.", "Not again...", "Easy, easy!",
	],
	&"grabbed_head": [
		"Not the head!", "My skull! My beautiful skull!", "Hey, that's my thinking part!",
		"Ow, my face!", "Watch the hair! ...I don't have hair.",
	],
	&"grabbed_limb": [
		"That's not a handle!", "Ow ow ow, my arm!", "Joints don't bend that way!",
		"Let go of my leg, you creep!", "Is this a hug? This isn't a hug.",
	],
	&"dangling": [
		"So... we just hanging out?", "My arms are getting tired. And I'm not even using them.",
		"Can you put me down now? Please?", "I'm getting a head rush.", "This is so undignified.",
	],
	&"upside_down": [
		"All the blood's going to my head!", "Wrong way up! Wrong way up!",
		"I can see up my own nose.", "Flip me back, damn it!",
	],
	&"thrown": [
		"AAAAAAAAAAH!", "WHEEEEE- no wait, AAAH!", "Nooooooo!", "Oh shiiiiit!", "Why meeeeee?!",
		"I can fly! I can't land!",
	],
	&"hit_light": [
		"Ow.", "Hey!", "Oof.", "Ouch!", "Rude.", "Ack!",
	],
	&"hit_medium": [
		"OW! What the hell?!", "That hurt, you jerk!", "Ow! Damn it!", "Son of a—!",
		"Ugh, my spleen!", "Hey! I bruise easy!",
	],
	&"hit_hard": [
		"FUCK!", "Holy shit, OW!", "Oh, you son of a bitch!", "AAGH! Goddammit!",
		"I felt that in my soul!", "Shit shit shit shit!", "Owww, my everything!",
	],
	&"hit_head": [
		"My HEAD!", "Ow, I think I saw stars.", "Brain damage! Brain damage!",
		"Owww, I can hear colors.", "My skull! What the hell, man?!",
	],
	&"hit_object": [
		"Who threw that?!", "Ow! Watch it!", "Was that a ball? Was that YOU?",
		"Hey, I'm not a target!", "Oh, real mature.",
	],
	&"hit_ceiling": [
		"Ow, the ceiling!", "Did I just hit the roof?", "Too high! Too high!",
	],
	&"survived": [
		"I'm okay! I'm okay!", "Ha! Didn't even hurt. ...It hurt.", "Nailed the landing. Sort of.",
		"Still alive, asshole!", "Is it over? Is it over?",
	],
	&"getting_up": [
		"Ugh...", "Alright, alright, I'm up.", "Okay. Okay. Walk it off.", "Everything hurts.",
		"Somebody get my good legs.",
	],
	&"low_health": [
		"I don't feel so good...", "Is that... is that a light?", "I need a nap. And a doctor.",
		"Please... no more...", "I think something's broken. Everything, maybe.",
	],
	&"revived": [
		"Wha... where am I?", "Five more minutes...", "Who turned out the lights?",
		"Ugh, my head. What year is it?", "Am I dead? Is this heaven? Why's it so blue?",
	],
	&"healed": [
		"Ahh, feeling better!", "Good as new! Mostly.", "Okay, I'm back to full fwend.",
	],
	&"idle": [
		"La la la...", "Nice weather out there.", "Hmm hm hmm.", "...", "So... what now?",
		"I wonder what's outside.", "Do you ever just... stand?", "*whistles*",
	],
	&"bored": [
		"Hellooo? Anybody there?", "I'm so bored I could die. Don't take that as a request.",
		"Are you still there?", "Guess I'll just stand here. Forever.", "*yawn*",
	],
	&"dizzy": [
		"Room's... spinning...", "Whoa, which way is up?", "I'm gonna hurl.", "Weeee... ugh.",
	],
	&"gravity_weird": [
		"Uh, why is the floor over there?", "This is NOT how gravity works!", "Who moved the floor?!",
	],
	&"zero_g": [
		"I'm floating! Is this space?", "Wheee, no gravity!", "I don't like this. I can't find down.",
	],
	&"gravity_normal": [
		"Oh thank god, down is down again.", "Gravity's back. Phew.",
	],
	&"slowmo": [
		"Wooooah... everything's... sloooow...", "Is... this... the matrix?",
	],
	&"cleaned": [
		"Thanks for cleaning up. I guess.", "Ooh, sparkly.", "Was all that blood mine?",
	],
}
