-- Stands in for the auto_install option the master branch had. On main, installing
-- a parser and turning on highlighting are separate steps and neither happens by
-- itself, so a FileType hook has to do both.

local M = {}

-- get_installed() scans the install dir, so cache it for the FileType hook.
local installed = {}

-- lang -> buffers waiting on an in-flight install, so that opening several files
-- of a new language highlights all of them.
local pending = {}

-- get_available() walks every parser definition; only consulted once an
-- unrecognised filetype actually turns up.
local available

local function start(buf, lang)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    -- Nvim may already have started the buffer, and starting twice replaces the
    -- highlighter without tearing the old one down.
    if not vim.b[buf].ts_highlight then
        pcall(vim.treesitter.start, buf, lang)
    end
    -- Not every language ships an indents query, and clobbering indentexpr would
    -- throw away a working core indent script.
    if vim.treesitter.query.get(lang, "indents") then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
end

function M.setup(ts)
    for _, lang in ipairs(ts.get_installed("parsers")) do
        installed[lang] = true
    end

    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            -- Filetypes and parser names disagree: sh is bash, cs is c_sharp.
            local lang = vim.treesitter.language.get_lang(args.match)
            if not lang then
                return
            end
            if installed[lang] then
                start(args.buf, lang)
                return
            end
            if pending[lang] then
                table.insert(pending[lang], args.buf)
                return
            end

            if not available then
                available = {}
                for _, l in ipairs(ts.get_available()) do
                    available[l] = true
                end
            end
            if not available[lang] then
                return
            end

            pending[lang] = { args.buf }
            ts.install(lang):await(function(err)
                local bufs = pending[lang]
                -- Cleared before the early return so a failed install is retried on
                -- the next buffer rather than wedging the language forever.
                pending[lang] = nil
                if err then
                    return
                end
                installed[lang] = true
                -- The install callback runs on the libuv loop, where most of the
                -- Vim API is off limits.
                vim.schedule(function()
                    for _, buf in ipairs(bufs) do
                        start(buf, lang)
                    end
                end)
            end)
        end,
    })
end

return M
