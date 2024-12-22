if vim.g.neovide then
	vim.g.neovide_remember_window_size = true
end

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("i", "<C-J>", vim.fn["codeium#Accept"], {
	expr = true,
	replace_keycodes = false,
})

vim.g.codeium_no_map_tab = true
-- disable copilot by default
vim.g.codeium_enabled = false

-- OBSIDIAN SYNC NOTES
local function obsidian_sync()
	-- Function to execute a shell command and return the output
	local function exec_cmd(cmd)
		local handle = io.popen(cmd)
		local result = handle:read("*a")
		handle:close()
		return result
	end

	-- Check for changes
	local git_status = exec_cmd("git status --porcelain")
	if git_status == "" then
		-- Check for remote changes
		local remote_status = exec_cmd("git fetch --dry-run 2>&1")
		if remote_status == "" then
			print("No changes to sync.")
			return
		else
			print("Remote changes detected, pulling...")
			-- Pull with rebase to avoid conflicts and preserve changes
			local pull_result = exec_cmd("git pull --rebase 2>&1")

			-- Check for conflicts
			if pull_result:find("CONFLICT") then
				print("There are conflicts. Please resolve them manually.")
				-- Get the list of conflicted files
				local conflict_files = exec_cmd("git diff --name-only --diff-filter=U")
				print("Conflicted files: " .. conflict_files:gsub("\n", ", "))
				-- Abort the rebase to avoid leaving the repository in an inconsistent state
				exec_cmd("git rebase --abort")
			else
				print("Sync complete and changes pulled from remote.")
			end
			return
		end
	end

	-- Stage all changes
	exec_cmd("git add .")

	-- Commit the changes
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local commit_msg = "sync from " .. timestamp
	exec_cmd(string.format('git commit -m "%s"', commit_msg))

	-- Pull with rebase to avoid conflicts and preserve changes
	local pull_result = exec_cmd("git pull --rebase 2>&1")

	-- Check for conflicts
	if pull_result:find("CONFLICT") then
		print("There are conflicts. Please resolve them manually.")
		-- Get the list of conflicted files
		local conflict_files = exec_cmd("git diff --name-only --diff-filter=U")
		print("Conflicted files: " .. conflict_files:gsub("\n", ", "))
		-- Abort the rebase to avoid leaving the repository in an inconsistent state
		exec_cmd("git rebase --abort")
	else
		-- Push the changes if the rebase was successful
		local push_result = exec_cmd("git push 2>&1")
		if push_result:find("error") then
			print("Push failed. Please check the errors.")
		else
			print("Sync complete and changes pushed to remote.")
		end
	end
end

-- Create the ObsidianSync command
vim.api.nvim_create_user_command("ObsidianSync", obsidian_sync, {})

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- NOTE: First, some plugins that don't require any configuration

	-- Git related plugins
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",

	-- Other
	"godlygeek/tabular",
	{
		"Olical/conjure",
		ft = { "clojure", "fennel", "python" }, -- etc
		lazy = true,
		init = function()
			-- Set configuration options here
			-- vim.g["conjure#debug"] = true
			vim.g["conjure#mapping#prefix"] = "J"
		end,

		-- Optional cmp-conjure integration
		dependencies = { "PaterJason/cmp-conjure" },
	},
	{
		"scalameta/nvim-metals",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		ft = { "scala", "sbt" },
		opts = function()
			local metals_config = require("metals").bare_config()

			metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

			metals_config.init_options.statusBarProvider = "off"

			metals_config.on_attach = function(client, bufnr)
				-- your on_attach function
				require("metals").setup_dap()
				local wk = require("which-key")

				wk.add({
					{ "<leader>f", group = "+find" },
					{ "<leader>w", group = "+window" },
					{ "<leader>b", group = "+buffer" },
					{ "<leader>c", group = "+code" },
					{ "<leader>g", group = "+git" },
					{ "<leader>n", group = "+notes" },
				})

				local nmap = function(keys, func, desc)
					if desc then
						desc = "[lsp] " .. desc
					end

					vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
				end

				local ccmd = function(cmd)
					return function()
						vim.cmd(cmd)
					end
				end

				local ft = vim.fn.getbufvar(bufnr, "&filetype")

				nmap("<leader>cn", vim.lsp.buf.rename, "re[N]ame")
				nmap("<leader>cc", vim.lsp.buf.code_action, "[C]ode action")

				nmap("<leader>cd", vim.lsp.buf.definition, "goto [D]efinition")
				nmap("<leader>cr", require("telescope.builtin").lsp_references, "goto [R]eferences")
				nmap("<leader>ci", vim.lsp.buf.implementation, "goto [I]mplementation")
				nmap("<leader>ct", vim.lsp.buf.type_definition, "[T]ype definition")
				-- nmap('<leader>cf', vim.lsp.buf.format, '[F]ormat buffer')
				nmap("<leader>cs", require("telescope.builtin").lsp_document_symbols, "document [s]ymbols")
				nmap("<leader>cS", require("telescope.builtin").lsp_dynamic_workspace_symbols, "workspace [S]ymbols")

				-- See :help K for why this keymap
				nmap("<leader>ck", vim.lsp.buf.hover, "Hover Documentation")
				nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
			end

			return metals_config
		end,
		config = function(self, metals_config)
			local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = self.ft,
				callback = function()
					require("metals").initialize_or_attach(metals_config)
				end,
				group = nvim_metals_group,
			})
		end,
	},
	{
		"PaterJason/cmp-conjure",
		lazy = true,
		config = function()
			local cmp = require("cmp")
			local config = cmp.get_config()
			table.insert(config.sources, { name = "conjure" })
			return cmp.setup(config)
		end,
	},

	-- AI
	"Exafunction/codeium.vim",
	-- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",

	-- NOTE: This is where your plugins related to LSP can be installed.
	--  The configuration is done below. Search for lspconfig to find it below.
	--

	-- NOTE THAT IMAGE VIEWING IS NOT SUPPORTED IN ZELLIJ
	-- {
	--   "vhyrro/luarocks.nvim",
	--   priority = 1001, -- this plugin needs to run before anything else
	--   opts = {
	--     rocks = { "magick" },
	--   },
	-- },
	-- {
	--   "3rd/image.nvim",
	--   dependencies = { "luarocks.nvim" },
	--   config = function()
	--     require("image").setup({
	--       backend = "kitty",
	--       max_height_window_percentage = 50,
	--       hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
	--       integrations = {
	--         markdown = {
	--           resolve_image_path = function(document_path, image_path, fallback)
	--             -- Helper function to check if a file exists
	--             local function file_exists(path)
	--               return vim.fn.filereadable(path) == 1
	--             end
	--
	--             -- Get the directory of the document
	--             local document_dir = vim.fn.fnamemodify(document_path, ":h")
	--             -- Define the assets directory
	--             local assets_dir = vim.fn.getcwd() .. "/assets/imgs/"
	--
	--             -- Construct full paths for the image in different locations
	--             local paths_to_check = {
	--               document_dir .. "/" .. image_path,
	--               assets_dir .. image_path
	--             }
	--
	--             -- Check each path
	--             for _, path in ipairs(paths_to_check) do
	--               if file_exists(path) then
	--                 return path
	--               end
	--             end
	--
	--             -- Fallback to default behavior if the image is not found in the custom paths
	--             return fallback(document_path, image_path)
	--           end,
	--         }
	--       }
	--     })
	--   end
	-- },
	{
		"MeanderingProgrammer/markdown.nvim",
		name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
		config = function()
			require("render-markdown").setup({
				-- Most of these are disabled because obsidian.nvim handles them in a better way (for my tastes)
				heading = {
					enabled = false,
				},
				code = {
					enabled = false,
				},
				bullet = {
					enabled = false,
				},
				checkbox = {
					enabled = false,
				},
				sign = {
					enabled = false,
				},
				win_options = {
					-- See :h 'conceallevel'
					conceallevel = {
						-- Used when not being rendered, get user setting
						default = vim.api.nvim_get_option_value("conceallevel", {}),
						rendered = 1,
					},
					-- See :h 'concealcursor'
					concealcursor = {
						-- Used when not being rendered, get user setting
						default = vim.api.nvim_get_option_value("concealcursor", {}),
						-- Used when being rendered, disable concealing text in all modes
						rendered = "",
					},
				},
				pipe_table = {
					enabled = true,
					cell = "overlay",
				},
			})
		end,
	},
	{
		"tamago324/nlsp-settings.nvim",
		dependencies = {
			"neovim/nvim-lspconfig", -- Optional but recommended dependency
		},
		config = function()
			require("nlspsettings").setup({
				config_home = vim.fn.stdpath("config") .. "/nlsp-settings",
				local_settings_root_markers = { ".git" },
				jsonls_append_default_schemas = true,
				append_default_schemas = true,
				loader = "json",
			})
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		lazy = false,
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = true,
			-- format_on_save = function(bufnr)
			--   -- Disable "format_on_save lsp_fallback" for languages that don't
			--   -- have a well standardized coding style. You can add additional
			--   -- languages here or re-enable it for the disabled ones.
			--   local disable_filetypes = { c = true, cpp = true, java = false, xml = true, html = true, javascript = true }
			--   return {
			--     timeout_ms = 500,
			--     lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
			--   }
			-- end,
			formatters_by_ft = {
				lua = { "stylua" },
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
				--
				-- You can use a sub-list to tell conform to run *until* a formatter
				-- is found.
				javascript = { { "prettierd", "prettier" } },
				java = { "jdtls", "clang-format" },
				php = { "php" },
				gdscript = { "gdformat" },
			},
			formatters = {
				gdformat = {
					command = "gdformat",
					args = {
						"$FILENAME",
					},
					stdin = false,
				},
				php = {
					command = "php-cs-fixer",
					args = {
						"fix",
						"$FILENAME",
						-- "--config=/your/path/to/config/file/[filename].php",
						-- "--allow-risky=yes",             -- if you have risky stuff in config, if not you dont need it.
					},
					stdin = false,
				},
			},
		},
	},

	{ --Note Taking notetaking notes note
		"epwalsh/obsidian.nvim",
		version = "*", -- recommended, use latest release instead of latest commit
		lazy = true,
		ft = "markdown",
		-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
		-- event = {
		--   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
		--   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
		--   "BufReadPre path/to/my-vault/**.md",
		--   "BufNewFile path/to/my-vault/**.md",
		-- },
		dependencies = {
			-- Required.
			"nvim-lua/plenary.nvim",

			-- see below for full list of optional dependencies 👇
		},
		opts = {
			preferred_link_style = "markdown",
			workspaces = {
				{
					name = "personal",
					path = "~/notes/vault1",
				},
				-- see below for full list of options 👇
			},

			-- -- Optional, customize how note IDs are generated given an optional title.
			-- ---@param title string|?
			-- ---@return string
			-- note_id_func = function(title)
			--   -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
			--   -- In this case a note with the title 'My new note' will be given an ID that looks
			--   -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
			--   local suffix = ""
			--   if title ~= nil then
			--     -- If title is given, transform it into valid file name.
			--     suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
			--   else
			--     -- If title is nil, just add 4 random uppercase letters to the suffix.
			--     for _ = 1, 4 do
			--       suffix = suffix .. string.char(math.random(65, 90))
			--     end
			--   end
			--   return tostring(os.time()) .. "-" .. suffix
			-- end,

			-- Optional, alternatively you can customize the frontmatter data.
			---@return table
			note_frontmatter_func = function(note)
				-- Add the title of the note as an alias.
				if note.title then
					note:add_alias(note.title)
				end

				local out = { title = note.title, id = note.id, aliases = note.aliases, tags = note.tags }

				-- `note.metadata` contains any manually added fields in the frontmatter.
				-- So here we just make sure those fields are kept in the frontmatter.
				if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
					for k, v in pairs(note.metadata) do
						out[k] = v
					end
				end

				return out
			end,
			-- Optional, by default when you use `:ObsidianFollowLink` on a link to an external
			-- URL it will be ignored but you can customize this behavior here.
			---@param url string
			follow_url_func = function(url)
				-- Open the URL in the default web browser.
				vim.fn.jobstart({ "open", url }) -- Mac OS
				-- vim.fn.jobstart({"xdg-open", url})  -- linux
			end,
		},
	},
	{ -- Linting
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				markdown = { "cspell" },
				java = { "checkstyle" },
				html = { "djlint" },
			}

			-- To allow other plugins to add linters to require('lint').linters_by_ft,
			-- instead set linters_by_ft like this:
			-- lint.linters_by_ft = lint.linters_by_ft or {}
			-- lint.linters_by_ft['markdown'] = { 'markdownlint' }
			--
			-- However, note that this will enable a set of default linters,
			-- which will cause errors unless these tools are available:
			-- {
			--   clojure = { "clj-kondo" },
			--   dockerfile = { "hadolint" },
			--   inko = { "inko" },
			--   janet = { "janet" },
			--   json = { "jsonlint" },
			--   markdown = { "vale" },
			--   rst = { "vale" },
			--   ruby = { "ruby" },
			--   terraform = { "tflint" },
			--   text = { "vale" }
			-- }
			--
			-- You can disable the default linters by setting their filetypes to nil:
			-- lint.linters_by_ft['clojure'] = nil
			-- lint.linters_by_ft['dockerfile'] = nil
			-- lint.linters_by_ft['inko'] = nil
			-- lint.linters_by_ft['janet'] = nil
			-- lint.linters_by_ft['json'] = nil
			-- lint.linters_by_ft['markdown'] = nil
			-- lint.linters_by_ft['rst'] = nil
			-- lint.linters_by_ft['ruby'] = nil
			-- lint.linters_by_ft['terraform'] = nil
			-- lint.linters_by_ft['text'] = nil

			-- Create autocommand which carries out the actual linting
			-- on the specified events.
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
	{
		-- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ "j-hui/fidget.nvim", tag = "legacy", opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			"folke/neodev.nvim",
		},
	},
	{
		"Hoffs/omnisharp-extended-lsp.nvim",
	},
	{
		"smoka7/hop.nvim",
		version = "*",
		opts = {
			keys = "etovxqpdygfblzhckisuran",
		},
		config = function()
			local hop = require("hop")
			hop.setup()
			local directions = require("hop.hint").HintDirection
			vim.keymap.set("n", "<leader><leader>/", function()
				hop.hint_char1({
					direction = directions.AFTER_CURSOR,
				})
			end, { desc = "Hop to [H]ere" }) -- Hop to here
		end,
	},
	{
		-- debugger | debugging | dap
		"mfussenegger/nvim-dap",
		dependencies = {
			-- Creates a beautiful debugger UI
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",

			-- Installs the debug adapters for you
			"williamboman/mason.nvim",
			"jay-babu/mason-nvim-dap.nvim",

			-- Add your own debuggers here
			"leoluz/nvim-dap-go",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			require("mason-nvim-dap").setup({
				-- Makes a best effort to setup the various debuggers with
				-- reasonable debug configurations
				automatic_installation = true,
				automatic_setup = true,

				-- You can provide additional configuration to the handlers,
				-- see mason-nvim-dap README for more information
				handlers = {},

				-- You'll need to check that you have the required things installed
				-- online, please don't ask me how to install them :)
				ensure_installed = {
					-- Update this to ensure that you have the debuggers for the langs you want
					-- 'delve',
					"java",
				},
			})

			dap.adapters.godot = {
				type = "server",
				host = "127.0.0.1",
				port = 6006,
			}

			dap.configurations.gdscript = {
				{
					type = "godot",
					request = "launch",
					name = "Launch Scene",
					program = "${workspaceFolder}",
					launch_scene = true,
				},
			}
			dap.configurations.scala = {
				{
					type = "scala",
					request = "launch",
					name = "RunOrTest",
					metals = {
						runType = "runOrTestFile",
						--args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
					},
				},
				{
					type = "scala",
					request = "launch",
					name = "Test Target",
					metals = {
						runType = "testTarget",
					},
				},
			}

			-- Basic debugging keymaps, feel free to change to your liking!
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Breakpoint" })

			-- Dap UI setup
			-- For more information, see |:help nvim-dap-ui|
			dapui.setup({
				-- Set icons to characters that are more likely to work in every terminal.
				--    Feel free to remove or use ones that you like more! :)
				--    Don't feel like these are good choices.
				icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
				controls = {
					icons = {
						pause = "‖",
						play = "▶",
						step_into = "⏎",
						step_over = "⤠",
						step_out = "⤟",
						step_back = "b",
						run_last = "▶▶",
						terminate = "⏻",
						disconnect = "⏏",
					},
				},
			})

			-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
			vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })

			dap.listeners.after.event_initialized["dapui_config"] = dapui.open
			dap.listeners.before.event_terminated["dapui_config"] = dapui.close
			dap.listeners.before.event_exited["dapui_config"] = dapui.close

			-- Install golang specific config
			require("dap-go").setup()
		end,
	},
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
		config = function()
			-- trouble keybinds | trouble keymaps
			vim.keymap.set("n", "<leader>xx", function()
				require("trouble").open("diagnostics")
			end, { desc = "[X]pen Trouble" })
			-- vim.keymap.set("n", "<leader>xw", function() require("trouble").open("workspace_diagnostics") end,
			--   { desc = "[W]orkpace diagnostics" })
			-- vim.keymap.set("n", "<leader>xd", function() require("trouble").open("document_diagnostics") end,
			--   { desc = "[D]ocument diagnostics" })
			vim.keymap.set("n", "<leader>xq", function()
				require("trouble").open("quickfix")
			end, { desc = "[Q]uickfix" })
			vim.keymap.set("n", "<leader>xl", function()
				require("trouble").open("loclist")
			end, { desc = "[L]oclist" })
		end,
	},

	{
		-- Autocompletion
		"hrsh7th/nvim-cmp",
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",

			-- Adds LSP completion capabilities
			"hrsh7th/cmp-nvim-lsp",

			-- Adds a number of user-friendly snippets
			"rafamadriz/friendly-snippets",
		},
	},
	{
		"nvim-tree/nvim-tree.lua",
		-- commit = '75ff64e',
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("nvim-tree").setup({
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")

					local function log(message)
						vim.api.nvim_out_write(message .. "\n")
					end

					local function get_clipboard_targets()
						local targets = vim.fn.systemlist("xclip -selection clipboard -t TARGETS -o")
						log("Clipboard targets: " .. table.concat(targets, ", "))
						return targets
					end

					local function generate_filename(extension)
						local date = os.date("%Y-%m-%d")
						local unique_number = tostring(math.random(1000, 9999))
						return date .. "_img_" .. unique_number .. extension
					end

					local function is_valid_file_path(path)
						return vim.fn.filereadable(path) == 1
					end

					local function resolve_filename_conflict(dir, filename)
						local new_filename = filename
						local count = 1
						while vim.fn.filereadable(dir .. "/" .. new_filename) == 1 do
							local name, ext = new_filename:match("(.+)(%..+)")
							new_filename = name .. "_" .. tostring(count) .. ext
							count = count + 1
						end
						return new_filename
					end

					local function handle_image_clipboard(nvim_tree_dir)
						local filename = generate_filename(".png")
						local filepath = nvim_tree_dir .. "/" .. filename
						os.execute("xclip -selection clipboard -t image/png -o > " .. vim.fn.shellescape(filepath))
						log("Image pasted as: " .. filepath)
					end

					local function handle_text_clipboard(nvim_tree_dir, clipboard_content)
						local filename = vim.fn.fnamemodify(clipboard_content, ":t")
						filename = resolve_filename_conflict(nvim_tree_dir, filename)
						local filepath = nvim_tree_dir .. "/" .. filename
						os.execute(
							"cp " .. vim.fn.shellescape(clipboard_content) .. " " .. vim.fn.shellescape(filepath)
						)
						log("File copied to: " .. filepath)
					end

					local function copy_file_to_nvim_tree_dir()
						local targets = get_clipboard_targets()
						local nvim_tree_lib = require("nvim-tree.lib")
						local node = nvim_tree_lib.get_node_at_cursor()
						local nvim_tree_dir = node.absolute_path

						if node.type ~= "directory" then
							nvim_tree_dir = vim.fn.fnamemodify(nvim_tree_dir, ":h")
							log("Current node is a file. Using its directory: " .. nvim_tree_dir)
						else
							log("Current node is a directory: " .. nvim_tree_dir)
						end

						if vim.tbl_contains(targets, "image/png") then
							log("Clipboard contains an image.")
							handle_image_clipboard(nvim_tree_dir)
						else
							local clipboard_content = vim.fn.system("xclip -selection clipboard -o")
							clipboard_content = clipboard_content:gsub("%s+", "") -- Remove whitespace

							if is_valid_file_path(clipboard_content) then
								log("Clipboard contains a valid file path.")
								handle_text_clipboard(nvim_tree_dir, clipboard_content)
							else
								log("Clipboard does not contain a valid file path. Using default paste.")
								api.fs.paste()
							end
						end

						-- Refresh nvim-tree
						vim.cmd("NvimTreeRefresh")
						log("nvim-tree refreshed.")
					end

					local function opts(desc)
						return {
							desc = "nvim-tree: " .. desc,
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
						}
					end
					-- default mappings
					api.config.mappings.default_on_attach(bufnr)

					vim.keymap.set("n", "p", copy_file_to_nvim_tree_dir, opts("PASTE"))
				end,

				actions = {
					use_system_clipboard = true,
				},
			})
		end,
	},

	-- Useful plugin to show you pending keybinds.
	{
		"folke/which-key.nvim",
		config = function()
			local wk = require("which-key")

			wk.add({
				{ "<leader>f", group = "+find" },
				{ "<leader>w", group = "+window" },
				{ "<leader>b", group = "+buffer" },
				{ "<leader>c", group = "+code" },
				{ "<leader>g", group = "+git" },
				{ "<leader>n", group = "+notes" },
			})
		end,
		opts = {},
	},
	{
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			-- See `:help gitsigns.txt`
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				vim.keymap.set(
					"n",
					"<leader>gp",
					require("gitsigns").prev_hunk,
					{ buffer = bufnr, desc = "[G]o to [P]revious Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>gn",
					require("gitsigns").next_hunk,
					{ buffer = bufnr, desc = "[G]o to [N]ext Hunk" }
				)
				vim.keymap.set(
					"n",
					"<leader>ph",
					require("gitsigns").preview_hunk,
					{ buffer = bufnr, desc = "[P]review [H]unk" }
				)
			end,
		},
	},

	{
		-- Theme gruvbox
		"ellisonleao/gruvbox.nvim",
		-- "Mofiqul/dracula.nvim",
		-- "folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			-- vim.cmd.colorscheme("tokyonight-moon")
			-- vim.cmd.colorscheme 'dracula'
			vim.cmd.colorscheme("gruvbox")
		end,
	},

	{
		-- Set lualine as statusline
		"nvim-lualine/lualine.nvim",
		-- See `:help lualine.txt`
		opts = {
			options = {
				icons_enabled = true,
				theme = "gruvbox",
				-- component_separators = '|',
				-- section_separators = '',
			},
			sections = {
				lualine_a = {
					"mode",
				},
				lualine_c = {
					"filename",
					"searchcount",
				},
			},
		},
	},

	{
		-- Add indentation guides even on blank lines
		"lukas-reineke/indent-blankline.nvim",
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help indent_blankline.txt`
		main = "ibl",
		opts = {
			indent = {
				char = "┊",
				-- show_trailing_blankline_indent = false,
			},
			whitespace = {
				remove_blankline_trail = true,
			},
		},
	},

	-- "gc" to comment visual regions/lines
	{ "numToStr/Comment.nvim", opts = {} },

	-- Fuzzy Finder (files, lsp, etc)
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- Fuzzy Finder Algorithm which requires local dependencies to be built.
			-- Only load if `make` is available. Make sure you have the system
			-- requirements installed.
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				-- NOTE: If you are having trouble with this installation,
				--       refer to the README for telescope-fzf-native for more instructions.
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
		},
	},

	{
		-- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
	},
	{
		-- markdown preview
		"iamcco/markdown-preview.nvim",
		config = function()
			vim.fn["mkdp#util#install"]()
			vim.g.mkdp_auto_start = 0
			vim.g.mkdp_auto_close = 1
			vim.g.mkdp_port = 9000
		end,
	},
}, {})

-- require 'extension.snippets'

-- Config

vim.o.hlsearch = true
vim.o.number = true
vim.o.relativenumber = true

vim.o.breakindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.wo.signcolumn = "yes"

vim.o.clipboard = "unnamedplus"

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.textwidth = 200

vim.o.completeopt = "menuone,noselect"

vim.o.termguicolors = true
vim.o.conceallevel = 1

--[[KEYMAPS | keymappings | maps | keybinds]]

-- misc | general
vim.keymap.set("n", "<Leader>h", ":nohlsearch<CR>", { desc = "Remove Highlight" })
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- file | directory
local toggle_replace = function()
	local api = require("nvim-tree.api")
	if api.tree.is_visible() then
		api.tree.close()
	else
		api.tree.open({
			current_window = true,
			find_file = true,
		})
	end
end

vim.keymap.set("n", "<Leader>dt", toggle_replace, { desc = "directory [T]oggle" })
vim.keymap.set("n", "<leader>fc", ":e ~/.config/nvim/init.lua<CR>", { desc = "[C]onfig" }) -- open configuration file

-- windows
vim.keymap.set("n", "<Leader>wv", ":vsplit<CR>", { desc = "Vertical Split" })
vim.keymap.set("n", "<Leader>ws", ":split<CR>", { desc = "Horizontal Split" })
vim.keymap.set("n", "<Leader>wh", "<c-w>h", { desc = "Move Left" })
vim.keymap.set("n", "<Leader>wj", "<c-w>j", { desc = "Move Down" })
vim.keymap.set("n", "<Leader>wk", "<c-w>k", { desc = "Move Up" })
vim.keymap.set("n", "<Leader>wl", "<c-w>l", { desc = "Move Right" })

-- buffer
vim.keymap.set("n", "<Leader>bn", "<c-w>l", { desc = "Move Right" })
vim.keymap.set("n", "<Leader>bx", ":bd<CR>", { desc = "Delete Buffer" })

local prev_buf = 0
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
	pattern = { "" },
	callback = function(ev)
		if vim.fn.buflisted(ev.buf) > 0 then
			prev_buf = ev.buf
		end
	end,
})

vim.keymap.set("n", "<Leader>bb", function()
	return ":" .. prev_buf .. "b<CR>"
end, { desc = "[B]ack buffer", expr = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})

-- Enable telescope fzf native, if installed
pcall(require("telescope").load_extension, "fzf")

vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "[F]ind [H]elp" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "[F]ind with Live [G]rep" })
vim.keymap.set("n", "<leader>fd", require("telescope.builtin").diagnostics, { desc = "[F]ind [D]iagnostics" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "[F]ind [B]uffers" })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require("nvim-treesitter.configs").setup({
	-- Add languages to be installed here that you want installed for treesitter
	ensure_installed = {
		"c",
		"cpp",
		"go",
		"lua",
		"python",
		"rust",
		"tsx",
		"typescript",
		"vimdoc",
		"vim",
		"markdown",
		"markdown_inline",
		"xml",
		"html",
		"java",
		"bash",
	},

	-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
	auto_install = false,

	highlight = { enable = true, additional_vim_regex_highlighting = { "markdown" } },
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-space>",
			node_incremental = "<c-space>",
			scope_incremental = "<c-s>",
			node_decremental = "<M-space>",
		},
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = "@class.outer",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		swap = {
			enable = true,
			swap_next = {
				["<leader>a"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>A"] = "@parameter.inner",
			},
		},
	},
})

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevelstart = 99

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
	local wk = require("which-key")

	wk.add({
		{ "<leader>f", group = "+find" },
		{ "<leader>w", group = "+window" },
		{ "<leader>b", group = "+buffer" },
		{ "<leader>c", group = "+code" },
		{ "<leader>g", group = "+git" },
		{ "<leader>n", group = "+notes" },
	})

	local nmap = function(keys, func, desc)
		if desc then
			desc = "[lsp] " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	local ccmd = function(cmd)
		return function()
			vim.cmd(cmd)
		end
	end

	local ft = vim.fn.getbufvar(bufnr, "&filetype")

	if ft == "markdown" then
		local nmap_notes = function(keys, func, desc)
			if desc then
				desc = "[Notes] " .. desc
			end

			vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
		end

		local vmap_notes = function(keys, func, desc)
			if desc then
				desc = "[Notes] " .. desc
			end

			vim.keymap.set("v", keys, func, { buffer = bufnr, desc = desc })
		end

		local function link_or_create()
			-- Get the current visual selection range
			local start_pos = vim.fn.getpos("'<")
			local end_pos = vim.fn.getpos("'>")

			-- Get the selected text
			vim.cmd('normal! "vy')
			local term = vim.fn.getreg("v")

			-- Function to handle the result of find_notes
			local function handle_find_notes_result(notes)
				if notes and #notes > 0 then
					vim.notify("Link exists, creating link with ObsidianLink", vim.log.levels.INFO)
					vim.cmd("normal! gv")
					vim.cmd("ObsidianLink")
				else
					vim.notify("Link does not exist, creating new link with ObsidianLinkNew", vim.log.levels.INFO)
					vim.fn.setpos("'<", start_pos)
					vim.fn.setpos("'>", end_pos)
					vim.cmd("normal! gv")
					vim.cmd("ObsidianLinkNew")
				end
			end

			-- Log the initial attempt to find notes
			vim.notify("Finding notes with obsidian.Client.find_notes", vim.log.levels.INFO)

			-- Get the obsidian client
			local client = require("obsidian").get_client()
			if client then
				-- Attempt to find notes matching the selected text
				local notes = client:find_notes(term)
				handle_find_notes_result(notes)
			else
				vim.notify("Failed to get obsidian client", vim.log.levels.ERROR)
			end
		end

		nmap_notes("<leader>mp", ccmd("MarkdownPreviewToggle"), "Toggle Markdown Preview")

		-- obsidian
		-- search/find
		nmap_notes("<leader>fn", ccmd("ObsidianSearch"), "find [n]otes")

		-- note specific operations
		nmap_notes("<leader>nn", ccmd("ObsidianNew"), "[n]ew note")
		nmap_notes("<leader>no", ccmd("ObsidianOpen"), "[o]pen obsidian")
		nmap_notes("<leader>np", ccmd("ObsidianPasteImg"), "[p]aste image")
		nmap_notes("<leader>nd", ccmd("ObsidianDailies"), "daily notes")
		nmap_notes("<leader>nt", ccmd("ObsidianTags"), "find note [t]ags")
		nmap_notes("<leader>ns", ccmd("ObsidianSync"), "[s]ync notes")

		vmap_notes("<leader>ne", ccmd("ObsidianExtractNote"), "[e]xtract note")

		-- links
		nmap_notes("<leader>nl", ccmd("ObsidianLinks"), "show note [l]inks")
		nmap_notes("<leader>nb", ccmd("ObsidianBacklinks"), "note [b]ack links")
		vmap_notes("<leader>nl", link_or_create, "[l]ink")
	end

	nmap("<leader>cn", vim.lsp.buf.rename, "re[N]ame")
	nmap("<leader>cc", vim.lsp.buf.code_action, "[C]ode action")

	nmap("<leader>cd", vim.lsp.buf.definition, "goto [D]efinition")
	nmap("<leader>cr", require("telescope.builtin").lsp_references, "goto [R]eferences")
	nmap("<leader>ci", vim.lsp.buf.implementation, "goto [I]mplementation")
	nmap("<leader>ct", vim.lsp.buf.type_definition, "[T]ype definition")
	-- nmap('<leader>cf', vim.lsp.buf.format, '[F]ormat buffer')
	nmap("<leader>cs", require("telescope.builtin").lsp_document_symbols, "document [s]ymbols")
	nmap("<leader>cS", require("telescope.builtin").lsp_dynamic_workspace_symbols, "workspace [S]ymbols")

	-- See `:help K` for why this keymap
	nmap("<leader>ck", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
end

-- [[LSP]]

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.

local servers = {
	-- clangd = {},
	-- gopls = {},
	-- pyright = {},
	-- rust_analyzer = {},
	-- tsserver = {},
	-- html = { filetypes = { 'html', 'twig', 'hbs'} },
	-- glsl_analyzer = {},
	-- checkstyle = {
	-- },
	emmet_language_server = {},
	lua_ls = {
		Lua = {

			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		},
	},
	biome = {},
	jinja_lsp = {
		filetypes = { "html" },
	},
	omnisharp = {
		-- cmd = {'./local/share/nvim/mason/bin/omnisharp', '--languageserver', '--hostPID', tostring(vim.fn.getpid())},
		enable_roslyn_analyzers = true,
	},
	html = {
		filetypes = {
			"html",
			"twig",
			"hbs",
			"jsx",
			-- "rust",
			"tsx",
			"css",
			"scss",
			"javascript",
			"typescript",
		},
		init_options = {
			-- userLanguages = {
			--   rust = "html"
			-- },
		},
	},
	tailwindcss = {
		filetypes = {
			"html",
			"twig",
			"hbs",
			"jsx",
			"tsx",
			-- "rust",
			"css",
			"scss",
			"javascript",
			"typescript",
			"javascriptreact",
			"typescriptreact",
			"php",
		},
		init_options = {
			-- userLanguages = {
			--   rust = "html"
			-- },
		},
	},
	jdtls = {},
}

local checkstyle = require("lint").linters.checkstyle
checkstyle.args = {
	"-c",
	"file://" .. vim.fn.getcwd() .. "/config/checkstyle/checkstyle.xml",
}

-- Setup neovim lua configuration
require("neodev").setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require("mason-lspconfig")

mason_lspconfig.setup({
	ensure_installed = vim.tbl_keys(servers),
})

require("mason-tool-installer").setup({ ensure_installed = vim.tbl_keys(servers or {}) })

mason_lspconfig.setup_handlers({
	function(server_name)
		require("lspconfig")[server_name].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			handlers = server_name == "omnisharp" and {
				["textDocument/definition"] = require("omnisharp_extended").handler,
			} or {},
			format = (servers[server_name] or {}).format,
			settings = servers[server_name],
			filetypes = (servers[server_name] or {}).filetypes,
			init_options = (servers[server_name] or {}).init_options,
		})
	end,
})

require("lspconfig")["gdscript"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	name = "godot",
	cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
})
require("lspconfig").glsl_analyzer.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()
luasnip.config.setup({
	updateevents = "TextChanged,TextChangedI",
})

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<C-p>"] = cmp.mapping.select_prev_item(),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete({}),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = {
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	},
})

-- Emoji shortcuts
local abbreviations = {
	{ ":smiley:", "😃" },
	{ ":wink:", "😉" },
	{ ":sad:", "☹️" },
	{ ":-(", "☹️" },
	{ ":angry:", "😡" },
	{ ":neutral_face:", "😐" },
	{ ":happy:", "😃" },
	{ ":-D", "😃" },
	{ ":heart_eyes:", "😍" },
	{ ":ok_hand:", "👌" },
	{ ":heavy_check_mark:", "✔️" },
	{ ":white_check_mark:", "✅" },
	{ ":ballot_box_with_check:", "☑️" },
	{ ":x:", "✖️" },
	{ ":no_entry_sign:", "🚫" },
	{ ":warning:", "⚠️" },
	{ ":bulb:", "💡" },
	{ ":pushpin:", "📌" },
	{ ":bomb:", "💣" },
	{ ":construction:", "🚧" },
	{ ":memo:", "📝" },
	{ ":point_right:", "👉" },
	{ ":thumbsup:", "👍" },
	{ ":book:", "📖" },
	{ ":link:", "🔗" },
	{ ":wrench:", "🔧" },
	{ ":information_source:", "ℹ️" },
	{ ":email:", "📧" },
	{ ":computer:", "💻" },
	{ ":hourglass:", "⏳" },
	{ ":stopwatch:", "⏱️" },
	{ ":arrow_right:", "➡️" },
	{ ":arrow_left:", "⬅️" },
	{ ":arrow_up:", "⬆️" },
	{ ":arrow_down:", "⬇️" },
	{ ":left_right_arrow:", "↔️" },
	{ ":up_down_arrow:", "↕️" },
	{ ":arrow_upper_left:", "↖️" },
	{ ":arrow_upper_right:", "↗️" },
	{ ":arrow_lower_left:", "↙️" },
	{ ":arrow_lower_right:", "↘️" },
	{ ":arrow_heading_up:", "⤴️" },
	{ ":arrow_heading_down:", "⤵️" },
	{ ":lock:", "🔒" },
	{ ":question:", "❓" },
	{ ":mag:", "🔍" },
	{ ":mag_right:", "🔎" },
	{ ":floppy_disk:", "💾" },
	{ ":exclamation:", "❗" },
	{ ":grey_exclamation:", "❕" },
	{ ":bangbang:", "‼️" },
	{ ":grey_question:", "❔" },
	{ ":interrobang:", "⁉️" },
	{ ":partying_face:", "🥳" },
	{ ":broom:", "🧹" },
	{ ":pencil2:", "✏️" },
	{ ":hammer:", "🔨" },
	{ ":adhesive_bandage:", "🩹" },
	{ ":open_file_folder:", "📂" },
	{ ":scissors:", "✂️" },
	{ ":map:", "🗺️" },
	{ ":eyes:", "👀" },
	{ ":beetle:", "🐞" },
	{ ":muscle:", "💪" },
	{ ":zap:", "⚡" },
	{ ":boom:", "💥" },
	{ ":sunny:", "☀️" },
	{ ":policeman:", "👮" },
	{ ":reminder_ribbon:", "🎗️" },
	{ ":game_die:", "🎲" },
	{ ":dart:", "🎯" },
	{ ":cool:", "🆒" },
	{ ":sos:", "🆘" },
	{ ":loudspeaker:", "📢" },
	{ ":atom:", "⚛️" },
	{ ":anchor:", "⚓" },
	{ ":building_construction:", "🏗️" },
	{ ":lipstick:", "💄" },
	{ ":clock3:", "🕒" },
	{ ":recycle:", "♻️" },
	{ ":cyclone:", "🌀" },
	{ ":bell:", "🔔" },
	{ ":fire:", "🔥" },
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true -- Disable wrapping (long lines won't auto-break)
		vim.opt_local.textwidth = 0 -- Set textwidth to 0 to prevent automatic breaking
	end,
})
