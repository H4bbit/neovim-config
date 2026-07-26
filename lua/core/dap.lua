local dap = require("dap")

dap.adapters.lldb = {
	type = "executable",
	command = "lldb-dap",
	name = "lldb",
}

dap.configurations.rust = {
	{
		name = "Rust - Debug",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/target/debug/")
		end,
		cwd = vim.fn.getcwd(),
		stopOnEntry = false,
		args = {},
	},
}

dap.configurations.c = {
	{
		name = "C - Debug",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/main")
		end,
		cwd = vim.fn.getcwd(),
		stopOnEntry = false,
		args = {},
	},
}
