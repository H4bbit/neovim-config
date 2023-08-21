local wilder = require("wilder")
wilder.setup({ modes = { ":", "/", "?" } })
wilder.set_option(
	"renderer",
	wilder.popupmenu_renderer({
		pumblend = 20,
		highlighter = {
			wilder.lua_pcre2_highlighter(), -- requires `luarocks install pcre2`
			wilder.lua_fzy_highlighter(), -- requires fzy-lua-native vim plugin found
			-- at https://github.com/romgrk/fzy-lua-native
		},
		highlights = {
			accent = wilder.make_hl("WilderAccent", "Pmenu", {
				{ a = 1 },
				{ a = 1 },
				{ background = "#313244", foreground = "#cba6f7" },
			}),
		},
		left = {
			" ",
			wilder.popupmenu_devicons(),
		},
		right = {
			" ",
			wilder.popupmenu_scrollbar(),
		},

		fuzzy = 1,
		fuzzy_filter = wilder.lua_fzy_filter(),
	})
)

wilder.set_option("pipeline", {
	wilder.branch(
		wilder.cmdline_pipeline({
			fuzzy = 1,
			fuzzy_filter = wilder.lua_fzy_filter(),
		}),
		wilder.vim_search_pipeline()
	),
})
