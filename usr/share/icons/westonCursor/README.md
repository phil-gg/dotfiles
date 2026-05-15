# westonCursor theme

## Instructions to generate

1. `clone` & `cd` to the same directory as this readme

2. Run this command to generate the KDE Plasma SVG cursor theme

    ```
    python3 src/build-svg-theme.py \
      --output-dir=cursors_scalable \
      --svg-dir=src/svg \
      --config-dir=src/config \
      --alias-file=src/cursorList \
      --nominal-size=96
    ```
    _See [jinliu/svg-cursor](https://github.com/jinliu/svg-cursor) for more details_

3. Run this command to generate the Xcursor theme

    ```
    python3 src/svg-theme-to-xcursor.py \
      --output-dir=cursors \
      --svg-dir=src/svg \
      --config-dir=src/config \
      --alias-file=src/cursorList
    ```

4. Copy to `/usr/share/icons/westonCursor`
