local opts = {noremap = true, silent = true}

-- Insert mode swap
vim.api.nvim_set_keymap('n', 'a', 'i', opts)
vim.api.nvim_set_keymap('n', 'h', 'a', opts)

-- Cursor movement to IJKL
vim.api.nvim_set_keymap('n', 'i', 'k', opts)
vim.api.nvim_set_keymap('n', 'k', 'j', opts)
vim.api.nvim_set_keymap('n', 'j', 'h', opts)