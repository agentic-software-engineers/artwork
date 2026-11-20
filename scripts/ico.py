"""Writes an ICO file whose frames are the given PNG files, in the order given."""
import struct
import sys


def png_size(data):
    # a PNG names its width and height in the IHDR chunk right after the signature
    return struct.unpack(">II", data[16:24])


def main(out, *pngs):
    frames = [open(path, "rb").read() for path in pngs]
    header = struct.pack("<HHH", 0, 1, len(frames))
    offset = len(header) + 16 * len(frames)
    entries = b""
    # each directory entry points at its PNG frame; 0 stands for 256 pixels
    for data in frames:
        width, height = png_size(data)
        entries += struct.pack("<BBBBHHII", width % 256, height % 256, 0, 0, 1, 32, len(data), offset)
        offset += len(data)
    with open(out, "wb") as f:
        f.write(header + entries + b"".join(frames))


if __name__ == "__main__":
    main(*sys.argv[1:])
