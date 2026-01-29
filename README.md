# simple mp4 compressor

drop the `.mp4` file onto the app icon in the dock and it compresses to the same directory

<p float="left">
  <img src="https://github.com/user-attachments/assets/e63359dd-6790-4de5-883e-318099d82f21" height="100" />
  <img src="https://github.com/user-attachments/assets/e2381102-2798-4ec2-af93-ebcaaa7deafb" width="auto" height="84" />
</p>


has prefixed `ffmpeg` settings that match mp4compress.com
```bash
ffmpeg -i input.mp4 -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart output.mp4
```

find built app at:
`~/Library/Developer/Xcode/DerivedData`
