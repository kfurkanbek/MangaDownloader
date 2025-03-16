-- Load dkjson for JSON parsing
-- dkjson.lua from https://github.com/LuaDist/dkjson
local json = require("dkjson")

-- Function to convert Google Drive URLs to direct download links
local function convert_link(url)
    local google_drive_pattern = "https://drive%.google%.com/uc%?export=view&id=([%w_-]+)"
    local file_id = url:match(google_drive_pattern)
    if file_id then
        return "https://drive.usercontent.google.com/download?id=" .. file_id .. "&export=view&authuser=0"
    else
        return url -- Return the original URL if it's not a Google Drive link
    end
end

-- Function to download an image using curl
local function download_image(url, save_path)
    local command = string.format("curl -s -L '%s' -o '%s'", url, save_path)
    return os.execute(command) -- Returns true if curl exits successfully
end

-- Function to convert a list of PNG images into a PDF
local function pdf_convert(png_list, pdf_name)
    local command = string.format("magick %s %s", png_list, pdf_name)
    print(command)
    return os.execute(command) -- Returns true if the conversion is successful
end

-- Function to check if a file exists
local function file_exists(name)
    local f = io.open(name, "r")
    if f then
        io.close(f)
        return true
    end
    return false
end

-- Function to create a directory if it doesn't exist
local function create_directory(path)
    os.execute("mkdir -p " .. path)
end

-- Function to remove a directory
local function remove_directory(path)
    os.execute("rm -rf " .. path)
end

-- Function to log messages to a file and print to console
local function log_message(output_buffer, message)
    table.insert(output_buffer, message)
    print(message)
end

-- Read the JSON file containing manga data
local file = io.open("manga.json", "r")
if not file then
    print("Error: JSON file not found!")
    return
end

local content = file:read("*a")
file:close()

-- Decode the JSON into a Lua table
local data, _, err = json.decode(content)
if err then
    print("Error decoding JSON:", err)
    return
end

-- Check for command-line arguments
local is_clean = arg[1] == "clean"
local is_manga = arg[1] == "manga"

-- Output buffer to store log data
local output_buffer = {}

-- Create base directory for storing downloaded images and PDFs
local base_dir = "data"
create_directory(base_dir)

-- Store manga metadata
log_message(output_buffer, "Title: " .. data.title)
log_message(output_buffer, "Author: " .. data.author)
log_message(output_buffer, "Artist: " .. data.artist)
log_message(output_buffer, "Description: " .. data.description)
log_message(output_buffer, "")

local cover_link = convert_link(data.cover)
if cover_link == "https://drive.google.com/uc?id=#################################" then
    log_message(output_buffer, " - Edit manga.json file with proper links!")
    log_message(output_buffer, " - Or copy 'gist source' from 'cubari.moe' website!")
    log_message(output_buffer, " - Skipping: " .. cover_link)
    return
end

local cover_filename = base_dir .. "/cover.png"
if file_exists(cover_filename) then
    log_message(output_buffer, " - Cover Exists: " .. cover_filename)
else
    local success = download_image(cover_link, cover_filename)
    if success then
        log_message(output_buffer, " - Cover Saved: " .. cover_filename)
    else
        log_message(output_buffer, " - Cover Failed to download: " .. cover_link)
    end
end

log_message(output_buffer, "")

local chapter_count = 0
local pdf_list = ""

-- Loop through each chapter
for chapter_number, chapter in pairs(data.chapters) do
    local chapter_dir = base_dir .. "/chapter_" .. chapter_number
    local pdf_filename = chapter_dir .. ".pdf"

    if file_exists(pdf_filename) then
        log_message(output_buffer, " - Exists: " .. pdf_filename)
    else
        create_directory(chapter_dir)

        -- Store chapter details
        log_message(output_buffer, "Chapter " .. chapter_number .. ":")
        log_message(output_buffer, "Title: " .. chapter.title)
        log_message(output_buffer, "Volume: " .. chapter.volume)
        log_message(output_buffer, "Last Updated: " .. os.date("%Y-%m-%d %H:%M:%S", tonumber(chapter.last_updated)))
        log_message(output_buffer, "Groups:")

        local link_count = 1
        local png_list = ""

        -- Add cover image to first chapter
        if chapter_number == "1" then
            png_list = cover_filename
        end

        -- Process each image link in the chapter
        for group, links in pairs(chapter.groups) do
            for _, link in ipairs(links) do
                local fixed_link = convert_link(link)
                local link_filename = chapter_dir .. "/link_" .. link_count .. ".png"

                if file_exists(link_filename) then
                    log_message(output_buffer, " - Exists: " .. link_filename)
                else
                    local success = download_image(fixed_link, link_filename)
                    if success then
                        log_message(output_buffer, " - Saved: " .. link_filename)
                    else
                        log_message(output_buffer, " - Failed to download: " .. fixed_link)
                    end
                end

                png_list = png_list .. " " .. link_filename
                link_count = link_count + 1
            end
        end

        log_message(output_buffer, "")

        -- Convert chapter images to PDF
        if file_exists(pdf_filename) then
            log_message(output_buffer, " - Exists: " .. pdf_filename)
        else
            if pdf_convert(png_list, pdf_filename) then
                log_message(output_buffer, " - Converted: " .. pdf_filename)
                if is_clean then
                    remove_directory(chapter_dir)
                end
            else
                log_message(output_buffer, " - Convert Failed: " .. pdf_filename)
            end
        end

        log_message(output_buffer, "")
        chapter_count = chapter_count + 1
        pdf_list = pdf_list .. " " .. pdf_filename
    end
end

-- Merge all chapter PDFs into a single manga PDF
local manga_filename = "manga.pdf"

if not is_manga then
    log_message(output_buffer, " - Skipping: " .. manga_filename)
else
    if file_exists(manga_filename) then
        log_message(output_buffer, " - Exists: " .. manga_filename)
    else
        if pdf_convert(pdf_list, manga_filename) then
            log_message(output_buffer, " - Converted: " .. manga_filename)
        else
            log_message(output_buffer, " - Convert Failed: " .. manga_filename)
        end
    end
end

log_message(output_buffer, "")

-- Save the output log to a file
local output_file = io.open("result.txt", "w")
output_file:write(table.concat(output_buffer, "\n"))
output_file:close()

log_message(output_buffer, "Total chapters: " .. chapter_count)
log_message(output_buffer, "Manga saved to manga.pdf")
log_message(output_buffer, "Data written to result.txt")
log_message(output_buffer, "Job completed!")
