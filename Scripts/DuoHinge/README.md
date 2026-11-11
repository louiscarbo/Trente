# duo-hinge

Sets the hinge angle of a booted iPhone Duo simulator from the command line, headless. Xcode's Device Hub is otherwise the only way to open the fold, and `simctl` and `devicectl` have no hinge command.

```sh
Scripts/DuoHinge/duo-hinge 180                               # open flat
Scripts/DuoHinge/duo-hinge 0                                 # closed
Scripts/DuoHinge/duo-hinge 90                                # half open
Scripts/DuoHinge/duo-hinge 180 --from 0 --duration 0.8       # animated sweep
Scripts/DuoHinge/duo-hinge 180 --orientation landscape-left  # open, inner display in portrait
Scripts/DuoHinge/duo-hinge 180 --device <udid> --verify      # print the state the simulator reports
```

The first run compiles the tool into `~/Library/Caches/duo-hinge/`; it rebuilds when the source changes.

## Options

| Option | Effect |
| --- | --- |
| `<angle>` | Degrees, 0 to 180. SpringBoard reports `.closed`, `.partiallyOpen` or `.openFlat`. |
| `--device <udid>` | Simulator to drive. Default: the booted one. |
| `--verify` | Waits for SpringBoard's "Hinge state changed" log line and prints it. Exits 1 if none appears, which also happens when the hinge was already in that state. |
| `--from <angle>` | Sweeps from that angle at 60 steps per second instead of jumping. |
| `--duration <seconds>` | Sweep length. Default 0.6. |
| `--orientation <name>` | Also sets the device orientation: `portrait`, `pud`, `landscape-left`, `landscape-right`, `faceup`, `facedown`, `ambiguous`. |
| `--standby <0\|1>` | Also reports the StandBy state. |
| `--hold <seconds>` | How long the tool stays connected after the last event. Default 1. |
| `--verbose` | Prints each event sent. |

## What to expect

- A simulator boots closed. The state lasts until the next boot, and survives the tool exiting.
- Displays for `simctl io <udid> screenshot --display=…`: `primary` is the outer display (1398×2034), `primary-1` the inner one.
- Open with the default `portrait` orientation, the inner display is landscape, 2853×2007. With `landscape-left` or `landscape-right` it is portrait, 2007×2853, the App Store screenshot size.
- A closed inner display keeps its last picture, so "is the screenshot black" does not tell you the fold is closed. Use `--verify`.

## How it works

Device Hub's hinge slider ends up as a HID event inside the simulator:

1. Device Hub calls CoreDevice's `HIDVendorDefined.send(usagePage: 0xFF61, usage: 0x5B, version: 0, data:)`.
2. The data is an `IOCFSerialize`d dictionary: `{source: "hinge-slider-control", type: "range", value: <degrees>}`. Orientation uses `{source: "orientation-picker-control", type: "enum", value: <name>}`, and StandBy is a keyboard event whose "down" field is the state.
3. In the simulator, `locationd` listens to HID services with that usage (`CMDeviceStateRelayManager`), turns the value into a real hinge-angle event, and SpringBoard folds or unfolds.

CoreDevice and CoreSimulator ship as arm64e only, so a tool that is not signed by Apple cannot load them on the Mac. `duo-hinge.m` therefore runs inside the simulator through `simctl spawn`: it registers a virtual HID service with usage page 0xFF61 and usage 0x5B and dispatches the same events from it. It needs no entitlements.

## Limits

- This relies on private behaviour of the simulator runtime. Checked on Xcode 27.2 with the iOS 27.1 runtime; a later runtime can change the usage or the payload, and the tool would then do nothing without an error. `--verify` catches that.
- There is no way to read the current angle back, only the state changes SpringBoard logs.
- Each run logs one harmless `Invalid usage page: 0` error in `locationd` when its service disconnects.
