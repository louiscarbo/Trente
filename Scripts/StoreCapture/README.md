# Store captures

Device names live in one place, at the top of `capture.sh`. Each one must match the Apple bezel the store kit frames it in.

| Variable | Simulator | Capture size | Bezel in the Figma kit |
| --- | --- | --- | --- |
| `IPHONE_NAME` | iPhone 18 Pro | 1206×2622 | Glacier |
| `IPAD_NAME` | iPad (A16) | 1640×2360 | Silver |
| `DUO_NAME` | iPhone Duo | closed 1398×2034, open 2007×2853, folded 2853×2007 | Star White |

Change a name here and the bezel in the kit together, never one without the other. A capture taken on a different device is cropped by the Screen node's fill.
