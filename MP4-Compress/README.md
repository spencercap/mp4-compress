# simple mp4 compressor

drop the `.mp4` file onto the app icon in the dock and it compresses to the same directory

has prefixed `ffmpeg` settings that match mp4compress.com
```bash
ffmpeg -i input.mp4 -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart output.mp4
```

find built app at:
`~/Library/Developer/Xcode/DerivedData`