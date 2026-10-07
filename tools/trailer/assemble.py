#!/usr/bin/env python3
"""Cuts the filmed parts into the 30-second trailer and lays the music under it.

Used by tools/trailer/make_trailer.sh (which films the parts first). Needs
ffmpeg. Usage:
    python3 tools/trailer/assemble.py <folder with the .avi and .log files> <output.mp4>

The edit is planned around the song's beat: "Hoshi o Kakeru" (the developer's
own track, on the HOSHIZORA 83 station) runs at 128 BPM, so one bar is
1.875 seconds. Its drop lands 17.0 s into the song; the trailer starts the
song at 9.0 s, so the drop hits 8 seconds in, right after "TAKE THE WHEEL."
Every shot after the drop is exactly one bar long.
"""
import os
import re
import subprocess
import sys

FPS = 30
SONG = "audio/radio/hoshizora_83/music/Hoshi_o_Kakeru.mp3"
SONG_START = 9.0       # Seconds into the song where the trailer starts.
LENGTH = 30.0          # Seconds.
BAR = 1.875            # One bar at 128 BPM.
SETTLE = 40            # Frames before a shot that may be borrowed (the camera settling; make_trailer.gd films 45).
DROP = 8.0             # Where the drop lands in the trailer.

# The edit: (shot, seconds). The shot names are the ones make_trailer.gd prints.
INTRO = [("cabin", 3.1), ("dispatch", 3.0), ("card_wheel", DROP - 6.1)]
AFTER_DROP = ["boost", "slot_machine", "casino", "cockpit_radio", "drive_through",
              "dust_storm", "creamery", "crash", "office", "cinema"]


def main() -> None:
    folder, output = sys.argv[1], sys.argv[2]
    shots = {}  # name -> (part, first frame)
    for part in ("rooms", "flight", "cards"):
        for line in open(os.path.join(folder, part + ".log")):
            match = re.match(r"CUT\|(\w+)\|(\d+)\|(\d+)", line.strip())
            if match:
                shots[match.group(1)] = (part, int(match.group(2)), int(match.group(3)))

    # Lay the edit out in whole frames, so the cuts stay locked to the beat.
    plan = []
    t = 0.0
    for name, seconds in INTRO:
        plan.append((name, t, t + seconds))
        t += seconds
    for i, name in enumerate(AFTER_DROP):
        plan.append((name, DROP + i * BAR, DROP + (i + 1) * BAR))
    plan.append(("card_title", plan[-1][2], LENGTH))

    inputs = ["rooms", "flight", "cards"]
    args = ["ffmpeg", "-v", "error", "-y"]
    for part in inputs:
        args += ["-i", os.path.join(folder, part + ".avi")]
    args += ["-i", SONG]
    filters = []
    labels = []
    for k, (name, start, end) in enumerate(plan):
        part, first, last = shots[name]
        frames = round(end * FPS) - round(start * FPS)
        hold = ""
        if first + frames - 1 > last:
            short = first + frames - 1 - last
            if part == "cards":
                # A title card: hold its last frame for the rest.
                hold = ",tpad=stop_mode=clone:stop=%d" % short
                frames -= short
            elif short <= SETTLE:
                first -= short  # Start a moment earlier, while the camera settles.
            else:
                sys.exit("Not enough footage for %s (%d frames wanted, %d filmed)" % (name, frames, last - first + 1))
        filters.append("[%d:v]trim=start_frame=%d:end_frame=%d,setpts=PTS-STARTPTS%s,fps=%d,format=yuv420p[v%d]"
                       % (inputs.index(part), first, first + frames, hold, FPS, k))
        labels.append("[v%d]" % k)
    filters.append("%sconcat=n=%d:v=1:a=0,fade=t=in:st=0:d=0.6[video]" % ("".join(labels), len(labels)))
    filters.append("[%d:a]atrim=start=%.3f:duration=%.3f,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.4,"
                   "afade=t=out:st=%.3f:d=2.8,volume=0.9[audio]" % (len(inputs), SONG_START, LENGTH, LENGTH - 2.8))
    args += ["-filter_complex", ";".join(filters), "-map", "[video]", "-map", "[audio]",
             "-c:v", "libx264", "-crf", "21", "-preset", "slow", "-pix_fmt", "yuv420p",
             "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-t", str(LENGTH), output]
    for name, start, end in plan:
        print("%-14s %5.2f - %5.2f" % (name, start, end))
    subprocess.run(args, check=True)
    print("Wrote", output)


if __name__ == "__main__":
    main()
