# Spatial Data Management

This is a repository of the course materials for Spatial Data Management. The materials are built as a Quarto project.

## Usage

- install [quarto](quarto.org)
- clone GitHub repository to a folder using git
- if using VSCode to write, navigate *above* the SpatialDataManagement repository, and type `code SpatialDataManagement`. The whole project folder will open in a new Code window.

This is all best used with the quarto extension for VSCode.

## Previewing and Rendering

Use `quarto preview` and `quarto render` from your command line to render.

To render at the same time both the book and slides ( and thus, generate new HTML, PDF, and slide HTML files), use `sh _slides.sh`.

## Content organisation

Content is organised in `qmd` files (quarto markdown). This is a standard markdown file, that allows to also include executable code.

Files to be used in the project are defined in `_quarto.yml`. Thus is by default the book content. To generate the slides, the script `sh _slides.sh` renames (temporarily) the `_quarto.yml`, then renames `_quarto_revealjs.yml` to `_quarto.yml`, runs `quarto render`, and then renames everything back.

The files to be used in a specific build are declared, in order, in the `quarto.yml` and `_quarto_revealjs.yml` files, respectively. 

The `qmd` files are also numbered, for ease, along the structure of the chapters (00_ up to XY_).

Each lecture/chapter is one `qmd` file.

Each lecture has some content that is slides only, or book only.



