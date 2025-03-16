# MangaDownloader
A Lua script that downloads manga images from provided links (including Google Drive links), converts them into PDFs, and compiles them into a single manga file.

## Features:
* Automated Image Downloading: Uses curl to fetch images from the provided links.
  * Google Drive URL Conversion: Converts shared Google Drive links into direct download links.
* PDF Compilation: Converts downloaded PNGs into PDFs using the convert command.
  * Chapter & Manga Compilation: Each chapter is saved as a PDF, and all chapters are compiled into a single manga file.

## Requirements:
* curl (for downloading images) : check 'curl --version'
* magick (ImageMagick for PNG to PDF conversion) : check 'magick --version'
* dkjson (for JSON parsing) : download 'dkjson.lua' file from [LuaDist/dkjson](https://github.com/LuaDist/dkjson)

## Usage:
* Place your manga JSON data inside manga.json.
  * Edit manga.json file with proper links
  * Or copy 'gist source' from [cubari.moe](https://cubari.moe)
* Run the script: 'lua manga_downloader.lua'
* Start reading manga.pdf!
* Find the downloaded images and PDFs inside the data/ directory.
