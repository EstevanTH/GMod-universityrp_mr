# Lesson scheduler

This add-on is a scheduler for lessons. A button to plan a course automatically shows when conditions are met.

The background of a planned lesson turns from green to red when it starts.

A player can have only 1 single planned course.

Lessons can be cancelled with the chat command `!lessons`.

[This add-on on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2133754720)

## Requirements

The *[Rooms location management library](https://github.com/EstevanTH/GMod-rooms_lib_mr)* is needed to determine locations.

The [DarkRP gamemode](https://github.com/FPtje/DarkRP) is needed to determine if a player is a teacher.

## Setting up

To determine if a player is a teacher, the [DarkRP gamemode](https://github.com/FPtje/DarkRP) is needed (or a gamemode with the same job structure). Teacher jobs must have their table with the field `teacher` set to `true`. Here is an example from `lua/darkrp_customthings/jobs.lua`:

```lua
TEAM_TEACHER_TRAINEE = DarkRP.createJob("Trainee Teacher", {
	color = Color(75, 75, 75),
	model = {
		"models/player/suits/male_01_open.mdl",
		"models/theforgottenarchitect/anita_sarkeesian_suit.mdl",
		"models/player/suits/male_02_open.mdl",
		"models/sal/female_02_suit.mdl",
		"models/player/suits/male_03_open.mdl",
		"models/player/suits/male_04_open.mdl",
		"models/player/suits/male_05_open.mdl",
		"models/player/suits/male_06_open.mdl",
		"models/player/suits/male_07_open.mdl",
		"models/player/suits/male_08_open.mdl",
		"models/player/suits/male_09_open.mdl",
	},
	description = [[Un professeur stagiaire découvre l'enseignement universitaire et dispense quelques cours.
		Avec un peu d'expérience et après avoir publié des cours, vous pourrez enfin devenir professeur titulaire !]],
	weapons = {},
	command = "traineeteacher",
	max = 3,
	salary = 45,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = true,
	teacher = true,
	category = "University",
	sortOrder = 102,
})
```

### Configuration files

- [`lua/config/universityrp_mr_agenda/shared.lua`](../_config/lua/config/universityrp_mr_agenda/shared.lua)

## Notes for the programmer

A lesson table is a table composed of the following fields:

```lua
local lesson = {
	cat = "Category name",
	title = "Lesson name",
	computer = Entity(.....), -- only filled when a computer is involved
}
```

## Triggered events

These are examples usages of `hook.Add()` for events triggered in this add-on.

- *:black_heart: SHARED:* **`findStartableLesson_mr`**  
    Looks up for a lesson available from an equipment, for the given player  
    For example, the lesson can be a slideshow loaded on a computer.  
    The provided lesson table does not have to be identical on the server and the client, but the actual lesson it refers to must be the same.  
    Warning: this event is called on every `Tick` clientside, so you should avoid expensive processing.

```lua
hook.Add("findStartableLesson_mr", "PUT IDENTIFIER HERE", function(ply)
	-- Return a lesson table.
end)
```

- *:black_heart: SHARED:* **`findStartableImplicitLesson_mr`**  
    Looks up for a lesson available from the player's location / situation / job / etc.  
    This event is only triggered if **`findStartableLesson_mr`** did not find a lesson.  
    It works the same way as the **`findStartableLesson_mr`** event.  
    Note: there is a configurable built-in hook that relies on the room & the team. It requires the *[Rooms location management library](https://github.com/EstevanTH/GMod-rooms_lib_mr)*.

```lua
hook.Add("findStartableImplicitLesson_mr", "PUT IDENTIFIER HERE", function(ply)
	-- Return a lesson table.
end)
```

- *:black_heart: SHARED:* **`canScheduleLesson_mr`**  
    Checks if the given player can schedule the given lesson table  
    This is called right after the events **`findStartableLesson_mr`** or **`findStartableImplicitLesson_mr`** found a lesson table.  
    The default decicision is `true` if the player is a teacher, `false` otherwise.  
    Clientside, when `true` is returned, the "Teach this lesson" button appears.  
    Warning: this event may be called on every `Tick` clientside, so you should avoid expensive processing.

```lua
hook.Add("canScheduleLesson_mr", "PUT IDENTIFIER HERE", function(ply, lesson)
	-- Return a boolean to override the default decision.
end)
```

- *:blue_heart: SERVER:* **`canUseLessonsCanceler_mr`**  
    Checks if the given player can use the **lessons canceler**  
    The default decision is determined by the result of `ply:IsAdmin()`.

```lua
hook.Add("canUseLessonsCanceler_mr", "PUT IDENTIFIER HERE", function(ply)
	-- Return a boolean to override the default decision.
end)
```

- *:orange_heart: CLIENT:* **`universityrp_mr_agenda:shouldSeeLesson`**  
    Checks if the local player should see the given lesson  
    The default decision is `true`.  
    The result of this event does not affect the **lessons canceler**.

```lua
hook.Add("universityrp_mr_agenda:shouldSeeLesson", "PUT IDENTIFIER HERE", function(lesson)
	-- Return a boolean to override the default decision.
end)
```

- *:black_heart: SHARED:* **`universityrp_mr_agenda:isRoomSuitable`**  
    Checks if the specified *(rooms_lib_mr.Room)* can be selected by the given player while planning a lesson  
    The default decision is `true`.  
    This event is triggered by the *Global agenda* entity.

```lua
hook.Add("universityrp_mr_agenda:isRoomSuitable", "PUT IDENTIFIER HERE", function(room, ply)
	-- Return a boolean to override the default decision.
end)
```

## Public functions

- *:blue_heart: SERVER:* `no value` **`universityrp_mr_agenda.cancelLessonByPlayer`**`(Player ply)`  
    Cancels a player's lesson
- *:black_heart: SHARED:* `boolean` **`universityrp_mr_agenda.cleanAgenda`**`()`  
    Removes from the schedule every lesson that should not be there anymore  
    Returns `true` if at least 1 lesson was removed, otherwise `false`  
    You probably should not need to call this yourself.
- *:black_heart: SHARED:* `table` **`universityrp_mr_agenda.getScheduled`**`(Player ply)`  
    Returns the lesson table of the specified player's planned lesson  
    The `computer` field is available serverside only.  
    In addition to usual room tables, the lesson table has extra fields:
    - `start`: *(float)* `CurTime()` value of the lesson beginning
    - `finish`: *(float)* `CurTime()` value of the lesson end
    - `building`: *(rooms_lib_mr.Building)* building where the lesson takes place
    - `room`: *(rooms_lib_mr.Room)* room where the lesson takes place
    - `teacher`: the player who planned the lesson
- *:blue_heart: SERVER:* `no value` **`universityrp_mr_agenda.insertToAgenda`**`(table lesson, int duration_min, Player ply, boolean bypassCountLimit)`  
    Inserts the specified lesson to the schedule.  
    `duration_min` is the duration in minutes.  
    `ply` is the teacher.  
    If `bypassCountLimit` (optional) is `true` then the lesson is planned even if it is over the limit setting `AgendaMax`.
- *:orange_heart: CLIENT:* `no value` **`universityrp_mr_agenda.lessonsCanceler`**`()`  
    Opens the **lessons canceler**
- *:black_heart: SHARED:* `boolean` **`universityrp_mr_agenda.playerIsTeacher`**`(Player ply)`  
    Returns if the player is a teacher (from their job)  
    It requires the DarkRP gamemode, otherwise `true` is always returned.
