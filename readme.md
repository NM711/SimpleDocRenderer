# Simple Doc Renderer

Terminal renderer made for the simple doc markup language. Crafted entirely in nim

## How to build and run?

### For UNIX and Linux

Create a local bin directory if you do not have one already over at: `mkdir ~/.local/bin`
In your `.bashrc` file or equivalent, append the following line at the end `export PATH=$HOME/.local/bin:$PATH`

1. `git clone https://github.com/NM711/SimpleDocRenderer.git`
2. `cd SimpleDocRenderer`
3. `nim c ./src/main.nim sdrenderer`
4. `mv sdrenderer ~/.local/bin/`
5. `sdrenderer ./path/to/simpledoc/file`
