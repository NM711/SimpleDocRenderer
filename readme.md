

https://github.com/user-attachments/assets/2bcbc79f-daec-47f8-a781-99eb9c82d97f

# Simple Doc Renderer

Terminal renderer made for the Simple Doc markup language. Crafted entirely in Nim!

## How to build and run?

### For UNIX and Linux

Create a local bin directory if you do not have one already over at: `mkdir ~/.local/bin`
In your `.bashrc` file or equivalent, append the following line at the end `export PATH=$HOME/.local/bin:$PATH`

1. `git clone https://github.com/NM711/SimpleDocRenderer.git`
2. `cd SimpleDocRenderer`
3. `nim c -o:./sdrenderer ./src/main.nim`
4. `mv sdrenderer ~/.local/bin/`
5. `sdrenderer ./path/to/simpledoc/file`
