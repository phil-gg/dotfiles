#!/usr/bin/env python3

import argparse
import tempfile
import subprocess
from pathlib import Path
from PySide6.QtSvg import QSvgRenderer
from PySide6.QtGui import QImage, QPainter
from PySide6.QtCore import QRectF

def main():
    parser = argparse.ArgumentParser(
                    prog='svg-theme-to-xcursor',
                    description='Generate XCursor from explicitly sized SVGs')
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--svg-dir', required=True)
    parser.add_argument('--config-dir', required=True)
    parser.add_argument('--alias-file', required=True)
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=False)

    svg_dir = Path(args.svg_dir)
    config_dir = Path(args.config_dir)

    with tempfile.TemporaryDirectory() as tmp_dir:
        
        # Build the physical cursors directly from the config files
        for config_file in config_dir.glob("*.cursor"):
            shape_name = config_file.stem
            print(f"Generate {shape_name}")

            shape_tmp_dir = Path(tmp_dir) / shape_name
            shape_tmp_dir.mkdir()

            with (shape_tmp_dir / "config").open('w') as out_config_file:
                for line in config_file.read_text().splitlines():
                    fields = line.split()
                    if len(fields) < 4:
                        continue

                    # Parse exact size and truncate hotspot decimals to 0dp integers
                    size = int(fields[0])
                    hotspot_x = int(float(fields[1]))
                    hotspot_y = int(float(fields[2]))
                    delay = fields[4] if len(fields) > 4 else "0"

                    # Map to the explicit SVG
                    filename = Path(fields[3]).stem
                    svg_file = svg_dir / f"{filename}.svg"
                    pngname = f"{filename}.png"

                    # Render the exact SVG directly to the exact target size
                    image = QImage(size, size, QImage.Format_ARGB32)
                    image.fill(0)
                    
                    painter = QPainter(image)
                    QSvgRenderer(str(svg_file)).render(painter, QRectF(0, 0, size, size))
                    painter.end()
                    
                    image.save(str(shape_tmp_dir / pngname))

                    # Write the cleanly formatted line for xcursorgen
                    out_config_file.write(f"{size} {hotspot_x} {hotspot_y} {pngname} {delay}\n")

            # Compile this shape using the temp directory
            subprocess.run(["xcursorgen", "--prefix", str(shape_tmp_dir), 
                            str(shape_tmp_dir / "config"), str(output_dir / shape_name)])

    # Generate symlinks from the explicit alias file
    alias_path = Path(args.alias_file)
    if alias_path.exists():
        print(f"\nProcessing aliases from {alias_path.name}...")
        for line in alias_path.read_text().splitlines():
            parts = line.split()
            if len(parts) >= 2:
                alias, target = parts[0], parts[1]
                
                if alias != target:  # Protect against self-referencing links
                    out_link = output_dir / alias
                    if not out_link.exists():
                        out_link.symlink_to(target)

if __name__ == '__main__':
    main()
