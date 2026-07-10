-- =========================================================
-- DimArch OS — yazi init.lua
-- Plugin setup calls. Plugins themselves are pinned in
-- package.toml and fetched via `ya pkg install`.
-- =========================================================

require("git"):setup({
	order = 1500,
})

require("full-border"):setup({
	type = ui.Border.ROUNDED,
})
