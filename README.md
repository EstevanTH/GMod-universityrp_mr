# Seat: zoom & volatile 3rd person

This add-on provides changes for the view when using seats & vehicles.

Its features are:
- The **first-person / third-person view selection** becomes **non-persistent** for seats & vehicles. It means that when you leave a seat, the view is restored to first-person.
- The **third-person zoom level** becomes **non-persistent** for seats & vehicles. It means that when you leave a seat, the zoom level is restored to its default.
- An extra view mode **first-person with full-page display** is available when you press `IN_DUCK` for seats. It is designed for *[Computer & projector: slideshows & videos](../../tree/prop_teacher_computer_mr)*.
- A **first-person zoom** is available on seats, if enabled with a hook. Just like the third-person zoom, it is available when using the mouse wheel.

[This add-on on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2130851011)

## Triggered events

These are examples usages of `hook.Add()` for events triggered in this add-on.

- *:orange_heart: CLIENT:* **`canUseFirstPersonZoom_mr`**  
    Checks if the first-person zoom is allowed  
    This is checked every time a `SetupMove` event happens, which is very often.

```lua
hook.Add("canUseFirstPersonZoom_mr", "PUT IDENTIFIER HERE", function(seat, ply)
	-- Return true to allow the first-person zoom.
end)
```

- *:orange_heart: CLIENT:* **`findFirstPersonOverlayComputer_mr`**  
    When switching views, if the seat is in first-person view, this lookups for a single `Entity` with full-page display capability.  
    If an `Entity` was returned, the **first-person view with full-page display** is selected, otherwise the third-person view is selected.  
    For instance, you can return a slideshow computer.  
    If several candidates are found then you probably should not return anything.

```lua
hook.Add("findFirstPersonOverlayComputer_mr", "PUT IDENTIFIER HERE", function(ply, seat)
	-- Return an Entity with full-page display capability.
end)
```

- *:orange_heart: CLIENT:* **`newFirstPersonOverlayComputer_mr`**  
    Broadcasts the new current `Entity` with full-page display capability or `nil`  
    This is where you enable and disable full-page displays.

```lua
hook.Add("newFirstPersonOverlayComputer_mr", "PUT IDENTIFIER HERE", function(eFirstPersonOverlayComputer)
	-- Never return anything.
end)
```
