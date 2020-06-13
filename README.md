# Seat natural leaving

This add-on improves the exit position when leaving seats. Instead of letting the game find an exit spot, the player will be positioned on the seat slightly further back. To achieve this and for comfort, seats do not collide with players anymore.

[This add-on on Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2128662255)

## Setting up

### Configuration files

- [`lua/config/seat_natural_leaving/server.lua`](../_config/lua/config/seat_natural_leaving/server.lua)

## Triggered events

These are examples usages of `hook.Add()` for events triggered in this add-on.

- *:blue_heart: SERVER:* **`seat_natural_leaving:shouldDo`**  
    Checks whether a seat should use the custom leaving process.  
    This is called several times, not only when leaving a seat.

```lua
hook.Add("seat_natural_leaving:shouldDo", "PUT IDENTIFIER HERE", function(seat, ply)
	-- Return a boolean to override the default decision.
end)
```

## Notes

To avoid conflicts, a certain number of rules is used to decide if a seat should use the custom exit spot. By default, the custom exit only happens when the player entered the seat by user input (the `CanPlayerEnterVehicle` event was triggered) and if the seat does not have a parent `Entity`. The event `seat_natural_leaving:shouldDo` allows you to override the default decision.

After exiting onto a custom exit point, the risk of accidentally sitting again instantly is very high. For this reason, the seat gets locked upon custom leaving and gets unlocked `1.` second later.
