# Slider focus and drag callbacks

`AddSlider` supports three optional, game-independent options:

```lua
section:AddSlider({
    Text = "Preview distance",
    Min = 0, Max = 100, Step = 0.01, Default = 20,
    RangeFocus = true,
    OnDragStarted = function(value)
        -- Show your application's preview at the current value.
    end,
    Callback = function(value)
        -- Update application state and preview immediately while dragging.
    end,
    OnDragEnded = function(value)
        -- End the preview, including cancellation or loss of window focus.
    end,
})
```

Focus begins on mouse/touch press, never hover. It hides only the owning
window's ScreenGui and shows a temporary track, fill, knob and numeric value.
The original UI instances and their transparency, visibility and layout are
untouched. Release restores the ScreenGui's saved Enabled value and removes
only the temporary focus overlay. Value changes update the overlay without
restarting focus. Sliders without RangeFocus keep their normal appearance.

Drag input belongs to the initiating mouse button or touch. Other fingers
cannot move or release it. Loss of window focus, destruction of the control
or window, and starting another slider end the previous drag. OnDragStarted
and OnDragEnded are interaction callbacks; SetValue/config loading does not
trigger them. Callback retains the normal value-change behavior.

The library does not create world objects, choose XZ/XYZ metrics, or know any
game's feature names. Preview geometry and lifetime belong to the caller.

Validation: run `lua tests/range-focus.test.lua` from this directory. This
executes the real slider implementation against mocked Roblox UI/input APIs;
it does not replace an in-game visual check.
