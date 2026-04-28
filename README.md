# AIFace

Processing sketches for an audio-reactive text face.

The main sketch is `forvoice/sketchvoice.pde`. It listens to audio input with `processing.sound`, changes the face color and expression based on the input level, and periodically speaks short lines with macOS `say`.

## Sketches

- `forvoice/sketchvoice.pde` - main audio-reactive face with voice controls
- `sketch.pde` - simpler audio-reactive face
- `test/test.pde` - audio input/device test sketch

