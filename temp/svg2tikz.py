#!/usr/bin/env python3
"""Convert potrace SVG output to TikZ \draw/\fill commands.

Potrace SVG structure:
  <g transform="translate(0, H) scale(0.1, -0.1)">
    <path d="M... c... l... z"/>
  </g>

The coordinates are in decipoints (0.1 pixel units), y-axis flipped.
We convert to cm scaled to fit a target width.
"""

import re
import sys
import xml.etree.ElementTree as ET

def parse_svg_path(d):
    """Parse SVG path d attribute into a list of (command, args) tuples."""
    # Tokenize: split into command letters and numbers
    tokens = re.findall(r'[MmCcLlHhVvZzSsQqTtAa]|[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?', d)

    commands = []
    i = 0
    current_cmd = None
    args = []

    while i < len(tokens):
        if tokens[i].isalpha():
            if current_cmd is not None:
                commands.append((current_cmd, args))
            current_cmd = tokens[i]
            args = []
            i += 1
        else:
            args.append(float(tokens[i]))
            i += 1

            # Check if we have enough args for the current command
            # and should emit + start new implicit command
            arg_counts = {
                'M': 2, 'm': 2, 'L': 2, 'l': 2,
                'H': 1, 'h': 1, 'V': 1, 'v': 1,
                'C': 6, 'c': 6, 'S': 4, 's': 4,
                'Q': 4, 'q': 4, 'T': 2, 't': 2,
                'Z': 0, 'z': 0, 'A': 7, 'a': 7,
            }
            expected = arg_counts.get(current_cmd, 0)
            if expected > 0 and len(args) == expected:
                commands.append((current_cmd, list(args)))
                args = []
                # Implicit repeat: M->L, m->l, others repeat
                if current_cmd == 'M':
                    current_cmd = 'L'
                elif current_cmd == 'm':
                    current_cmd = 'l'

    if current_cmd is not None and (args or current_cmd in ('z', 'Z')):
        commands.append((current_cmd, args))

    return commands


def svg_paths_to_tikz(svg_file, target_width_cm=8.0, min_path_points=3):
    """Convert SVG paths to TikZ commands."""
    tree = ET.parse(svg_file)
    root = tree.getroot()
    ns = {'svg': 'http://www.w3.org/2000/svg'}

    # Get dimensions from SVG
    width_pt = float(root.get('width', '725').replace('pt', ''))
    height_pt = float(root.get('height', '513').replace('pt', ''))

    # Potrace uses transform: translate(0, H) scale(0.1, -0.1)
    # So raw path coords are in decipoints: x_real = x*0.1, y_real = H - y*0.1
    # We want to convert to cm, scaled to target_width
    scale = target_width_cm / width_pt  # cm per pt

    paths = root.findall('.//svg:path', ns)
    if not paths:
        # Try without namespace
        paths = root.findall('.//{http://www.w3.org/2000/svg}path')
    if not paths:
        paths = [e for e in root.iter() if e.tag.endswith('path')]

    print(f"% SVG2TikZ: {len(paths)} paths, {width_pt}x{height_pt} pt")
    print(f"% Scale: {scale:.4f} cm/pt, target width: {target_width_cm} cm")
    print(f"% Coordinate system: origin at bottom-left, y up")
    print()

    tikz_lines = []
    path_stats = []

    for pi, path_el in enumerate(paths):
        d = path_el.get('d', '')
        if not d:
            continue

        commands = parse_svg_path(d)
        if len(commands) < min_path_points:
            continue

        # Convert to absolute coordinates and transform
        cx, cy = 0.0, 0.0  # current position (in decipoints)
        sx, sy = 0.0, 0.0  # subpath start

        tikz_parts = []
        point_count = 0
        min_x, max_x = float('inf'), float('-inf')
        min_y, max_y = float('inf'), float('-inf')

        for cmd, args in commands:
            arg_needed = {'M':2,'m':2,'L':2,'l':2,'C':6,'c':6,'H':1,'h':1,'V':1,'v':1,'S':4,'s':4}
            if cmd in arg_needed and len(args) < arg_needed[cmd]:
                continue  # skip malformed commands

            if cmd == 'M':
                cx, cy = args[0], args[1]
                sx, sy = cx, cy
                # Transform: decipoints -> pt -> cm, flip y
                tx = cx * 0.1 * scale
                ty = cy * 0.1 * scale
                tikz_parts.append(f"({tx:.3f},{ty:.3f})")
                point_count += 1
                min_x, max_x = min(min_x, tx), max(max_x, tx)
                min_y, max_y = min(min_y, ty), max(max_y, ty)

            elif cmd == 'm':
                cx += args[0]
                cy += args[1]
                sx, sy = cx, cy
                tx = cx * 0.1 * scale
                ty = cy * 0.1 * scale
                tikz_parts.append(f"({tx:.3f},{ty:.3f})")
                point_count += 1
                min_x, max_x = min(min_x, tx), max(max_x, tx)
                min_y, max_y = min(min_y, ty), max(max_y, ty)

            elif cmd == 'c':
                # Relative cubic bezier
                dx1, dy1, dx2, dy2, dx, dy = args
                c1x = (cx + dx1) * 0.1 * scale
                c1y = (cy + dy1) * 0.1 * scale
                c2x = (cx + dx2) * 0.1 * scale
                c2y = (cy + dy2) * 0.1 * scale
                ex = (cx + dx) * 0.1 * scale
                ey = (cy + dy) * 0.1 * scale
                tikz_parts.append(f".. controls ({c1x:.3f},{c1y:.3f}) and ({c2x:.3f},{c2y:.3f}) .. ({ex:.3f},{ey:.3f})")
                cx += dx
                cy += dy
                point_count += 1
                min_x, max_x = min(min_x, ex), max(max_x, ex)
                min_y, max_y = min(min_y, ey), max(max_y, ey)

            elif cmd == 'C':
                c1x = args[0] * 0.1 * scale
                c1y = args[1] * 0.1 * scale
                c2x = args[2] * 0.1 * scale
                c2y = args[3] * 0.1 * scale
                ex = args[4] * 0.1 * scale
                ey = args[5] * 0.1 * scale
                tikz_parts.append(f".. controls ({c1x:.3f},{c1y:.3f}) and ({c2x:.3f},{c2y:.3f}) .. ({ex:.3f},{ey:.3f})")
                cx, cy = args[4], args[5]
                point_count += 1
                min_x, max_x = min(min_x, ex), max(max_x, ex)
                min_y, max_y = min(min_y, ey), max(max_y, ey)

            elif cmd == 'l':
                cx += args[0]
                cy += args[1]
                tx = cx * 0.1 * scale
                ty = cy * 0.1 * scale
                tikz_parts.append(f"-- ({tx:.3f},{ty:.3f})")
                point_count += 1
                min_x, max_x = min(min_x, tx), max(max_x, tx)
                min_y, max_y = min(min_y, ty), max(max_y, ty)

            elif cmd == 'L':
                cx, cy = args[0], args[1]
                tx = cx * 0.1 * scale
                ty = cy * 0.1 * scale
                tikz_parts.append(f"-- ({tx:.3f},{ty:.3f})")
                point_count += 1
                min_x, max_x = min(min_x, tx), max(max_x, tx)
                min_y, max_y = min(min_y, ty), max(max_y, ty)

            elif cmd == 'h':
                cx += args[0]
                tx = cx * 0.1 * scale
                ty = cy * 0.1 * scale
                tikz_parts.append(f"-- ({tx:.3f},{ty:.3f})")
                point_count += 1

            elif cmd == 'v':
                cy += args[0]
                tx = cx * 0.1 * scale
                ty = cy * 0.1 * scale
                tikz_parts.append(f"-- ({tx:.3f},{ty:.3f})")
                point_count += 1

            elif cmd in ('z', 'Z'):
                tikz_parts.append("-- cycle")
                cx, cy = sx, sy

            # Skip unknown commands
            else:
                pass

        if point_count >= min_path_points and tikz_parts:
            bbox_w = max_x - min_x
            bbox_h = max_y - min_y
            path_stats.append((pi, point_count, bbox_w, bbox_h, min_x, min_y, max_x, max_y))

            # Build tikz draw command
            path_str = "\n    ".join(tikz_parts)
            tikz_lines.append(
                f"  % Path {pi}: {point_count} pts, bbox ({min_x:.2f},{min_y:.2f})-({max_x:.2f},{max_y:.2f}) size {bbox_w:.2f}x{bbox_h:.2f}\n"
                f"  \\fill[spacecadet]\n    {path_str};\n"
            )

    # Print stats
    print(f"% {len(tikz_lines)} paths with >= {min_path_points} points")
    print(f"% Path summary (index, points, width, height):")
    for pi, pc, bw, bh, mnx, mny, mxx, mxy in sorted(path_stats, key=lambda x: -x[2]*x[3]):
        print(f"%   Path {pi:3d}: {pc:4d} pts, {bw:.2f}x{bh:.2f} cm at ({mnx:.2f},{mny:.2f})")
    print()

    # Output TikZ
    print("\\begin{tikzpicture}[scale=1.0]")
    for line in tikz_lines:
        print(line)
    print("\\end{tikzpicture}")


if __name__ == '__main__':
    svg_file = sys.argv[1] if len(sys.argv) > 1 else 'traced.svg'
    target_w = float(sys.argv[2]) if len(sys.argv) > 2 else 8.0
    svg_paths_to_tikz(svg_file, target_width_cm=target_w)
